# Cross-Circle Tagging & Lockout Visibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement chain joining, lockout-level post visibility, per-participant scoring, and cross-circle display tiers so users in shared lockouts can see each other's posts regardless of direct friendship.

**Architecture:** New `lockout_participants` table (dual-written alongside existing participants array) tracks join chain and individual scores. Feed/post visibility adds lockout-based OR condition. Client computes distance tiers from `joined_via` + local friend list. No changes to completion/scoring RPCs that use the array.

**Tech Stack:** PostgreSQL (Supabase migrations), Flutter/Dart (Freezed + Riverpod), RLS policies, pg triggers

**Spec:** `docs/superpowers/specs/2026-04-15-cross-circle-tagging-design.md`

---

## File Map

### New files
- `supabase/migrations/YYYYMMDDHHMMSS_lockout_participants.sql` — table, indexes, RLS, owner-row trigger
- `supabase/migrations/YYYYMMDDHHMMSS_chain_joining.sql` — rewrite join_lockout_session, update get_friends_locked_out
- `supabase/migrations/YYYYMMDDHHMMSS_lockout_feed_visibility.sql` — update get_user_feed, get_post_by_id, get_post_comments, new RLS policies on posts/post_media
- `supabase/migrations/YYYYMMDDHHMMSS_lockout_notifications.sql` — lockout_tag notification type, notify_lockout_participants function, connection_requests context columns, notification cleanup
- `lib/core/features/lockout/data/dtos/lockout_participant_dto.dart` — Freezed DTO
- `lib/core/features/lockout/domain/models/lockout_participant_model.dart` — domain model
- `lib/core/features/lockout/domain/utilities/participant_distance.dart` — client-side distance calculator
- `lib/presentation/pages/post_detail/components/post_detail_participants.dart` — tiered participant display widget
- `lib/presentation/pages/profile/views/limited_profile_view.dart` — limited profile screen (username, avatar, add to circle)

### Modified files
- `lib/core/features/lockout/data/dtos/lockout_session_dto.dart` — add `joined_via` field
- `lib/core/features/lockout/domain/models/lockout_session_model.dart` — add `joinedVia` field
- `lib/core/features/lockout/data/mappers/lockout_session_dto_to_model_mapper.dart` — map new field
- `lib/core/features/lockout/data/services/lockout_session_service.dart` — updateScore writes to lockout_participants
- `lib/core/features/post/domain/hooks/use_post_creation.dart` — remove participant auto-tagging
- `lib/core/features/post/domain/models/feed_post_model.dart` — add lockout participant fields
- `lib/presentation/pages/post_detail/components/post_detail_tags.dart` — show mentions only, delegate participants to new widget
- `lib/presentation/pages/post_detail/views/post_detail_overlay.dart` — integrate participant widget
- `lib/presentation/pages/manual_lockout/components/friend_locked_out_item.dart` — show distance tier labels
- `lib/presentation/pages/manual_lockout/components/friends_locked_out_list.dart` — handle cross-circle participants
- `lib/presentation/components/share_card/share_post_dialog.dart` — "Locked out with N others"
- `lib/core/features/connection/data/services/connection_service.dart` — add context params to send_connection_request

---

## Task 1: Create `lockout_participants` table + owner-row trigger

**Files:**
- Create: `supabase/migrations/YYYYMMDDHHMMSS_lockout_participants.sql`

This is the foundation. All other tasks depend on it.

- [ ] **Step 1: Write the migration SQL**

```sql
-- ============================================================================
-- LOCKOUT PARTICIPANTS TABLE
-- ============================================================================
-- Replaces the implicit participants UUID[] array with a proper relational
-- table. Tracks join chain (joined_via), individual scores, and timestamps.
-- The array is KEPT for backwards compatibility with existing RPCs.
-- ============================================================================

-- 1. Create table
CREATE TABLE IF NOT EXISTS lockout_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES lockout_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  joined_via UUID REFERENCES profiles(id) ON DELETE SET NULL,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  goback_score SMALLINT,
  battery_was_charging BOOLEAN,
  step_count SMALLINT,
  UNIQUE (session_id, user_id)
);

-- 2. Indexes
CREATE INDEX idx_lockout_participants_user ON lockout_participants(user_id);
CREATE INDEX idx_lockout_participants_session ON lockout_participants(session_id);

-- 3. RLS
ALTER TABLE lockout_participants ENABLE ROW LEVEL SECURITY;

-- Users can read participants for sessions they are in or where owner is a friend
CREATE POLICY "Users can read lockout participants"
  ON lockout_participants FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM lockout_participants lp2
      WHERE lp2.session_id = lockout_participants.session_id
        AND lp2.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM lockout_sessions ls
      JOIN friendships f ON
        (f.user_a_id = auth.uid() AND f.user_b_id = ls.user_id)
        OR (f.user_b_id = auth.uid() AND f.user_a_id = ls.user_id)
      WHERE ls.id = lockout_participants.session_id
    )
  );

-- Users can only insert/update their own rows
CREATE POLICY "Users can insert own participant rows"
  ON lockout_participants FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own participant rows"
  ON lockout_participants FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- 4. Trigger: auto-insert owner row when lockout session is created
CREATE OR REPLACE FUNCTION trigger_insert_lockout_owner_participant()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
  VALUES (NEW.id, NEW.user_id, NULL, NEW.started_at)
  ON CONFLICT (session_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_lockout_owner_participant
  AFTER INSERT ON lockout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_insert_lockout_owner_participant();

-- 5. Update update_lockout_score to write to lockout_participants
CREATE OR REPLACE FUNCTION update_lockout_score(
  p_session_id UUID,
  p_score INT,
  p_battery_was_charging BOOLEAN DEFAULT NULL,
  p_step_count INT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  -- Write to lockout_participants (new: per-participant scoring)
  UPDATE lockout_participants
  SET goback_score = LEAST(100, GREATEST(0, p_score)),
      battery_was_charging = p_battery_was_charging,
      step_count = CASE WHEN p_step_count IS NOT NULL
                        THEN LEAST(32767, GREATEST(0, p_step_count))
                        ELSE NULL END
  WHERE session_id = p_session_id AND user_id = v_user_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  RETURN json_build_object('success', true);
END;
$$;

-- 6. Backfill existing sessions: insert owner rows for active sessions
INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
SELECT ls.id, ls.user_id, NULL, ls.started_at
FROM lockout_sessions ls
WHERE ls.completed_at IS NULL
  AND (ls.is_open_ended OR ls.ends_at > NOW())
ON CONFLICT (session_id, user_id) DO NOTHING;

-- 7. Backfill existing participants from the array
INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
SELECT ls.id, unnest(ls.participants), NULL, ls.started_at
FROM lockout_sessions ls
WHERE ls.completed_at IS NULL
  AND (ls.is_open_ended OR ls.ends_at > NOW())
  AND COALESCE(array_length(ls.participants, 1), 0) > 0
ON CONFLICT (session_id, user_id) DO NOTHING;
```

- [ ] **Step 2: Apply migration to local Supabase**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && supabase db reset`
Expected: Migration applies cleanly, table created, trigger works.

- [ ] **Step 3: Verify trigger works — create a session and check for owner row**

```sql
-- In Supabase SQL editor or psql:
SELECT * FROM lockout_participants WHERE session_id = (
  SELECT id FROM lockout_sessions ORDER BY created_at DESC LIMIT 1
);
```
Expected: Owner row exists with `joined_via = NULL`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/*_lockout_participants.sql
git commit -m "feat: add lockout_participants table with owner trigger and per-participant scoring"
```

---

## Task 2: Rewrite `join_lockout_session` for chain joining

**Files:**
- Create: `supabase/migrations/YYYYMMDDHHMMSS_chain_joining.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- ============================================================================
-- CHAIN JOINING
-- ============================================================================
-- Rewrites join_lockout_session to allow joining if friends with ANY participant
-- (not just the owner). Records joined_via in lockout_participants table.
-- Also dual-writes to the participants array for backwards compatibility.
-- ============================================================================

CREATE OR REPLACE FUNCTION join_lockout_session(p_lockout_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_lockout RECORD;
  v_joined_via UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  -- Check if user is already in an active lockout (own or joined)
  IF EXISTS (
    SELECT 1 FROM lockout_sessions ls
    WHERE (ls.user_id = v_user_id OR v_user_id = ANY(ls.participants))
      AND (ls.is_open_ended OR ls.ends_at > NOW())
      AND ls.post_id IS NULL
      AND ls.completed_at IS NULL
  ) THEN
    RETURN json_build_object('success', false, 'error', 'You are already in an active lockout');
  END IF;

  SELECT * INTO v_lockout FROM lockout_sessions WHERE id = p_lockout_id;

  IF v_lockout IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout not found');
  END IF;

  IF v_lockout.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  IF (NOT v_lockout.is_open_ended AND v_lockout.ends_at < NOW()) OR v_lockout.post_id IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  -- Check if already joined
  IF v_user_id = ANY(v_lockout.participants) THEN
    RETURN json_build_object('success', true, 'message', 'Already joined this lockout');
  END IF;

  -- CHAIN JOINING: find a friend who is already in the lockout (owner or participant)
  SELECT friend_id INTO v_joined_via
  FROM (
    -- Check owner
    SELECT v_lockout.user_id AS friend_id
    UNION ALL
    -- Check existing participants
    SELECT unnest(v_lockout.participants) AS friend_id
  ) candidates
  WHERE EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = v_user_id AND f.user_b_id = candidates.friend_id)
       OR (f.user_b_id = v_user_id AND f.user_a_id = candidates.friend_id)
  )
  LIMIT 1;

  IF v_joined_via IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'You must be friends with someone in this lockout');
  END IF;

  -- Set joined_via to NULL if the link is the session owner (direct friend of owner)
  IF v_joined_via = v_lockout.user_id THEN
    v_joined_via := NULL;
  END IF;

  -- Dual write: array (backwards compat) + table (new)
  UPDATE lockout_sessions
  SET participants = array_append(participants, v_user_id)
  WHERE id = p_lockout_id;

  INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
  VALUES (p_lockout_id, v_user_id, v_joined_via, NOW())
  ON CONFLICT (session_id, user_id) DO UPDATE
  SET joined_via = EXCLUDED.joined_via, joined_at = EXCLUDED.joined_at;

  -- In-app notification to owner
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  -- Push: notify owner that someone joined their lockout
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('lockout_joined', jsonb_build_object(
    'owner_id', v_lockout.user_id,
    'joiner_id', v_user_id,
    'lockout_id', p_lockout_id
  ));

  -- Push: notify joiner's friends
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('friend_joins_lockout', jsonb_build_object(
    'joiner_id', v_user_id,
    'owner_id', v_lockout.user_id,
    'lockout_id', p_lockout_id
  ));

  -- Notify the joined_via user if they're not the owner
  IF v_joined_via IS NOT NULL THEN
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('chain_join', jsonb_build_object(
      'joined_via_id', v_joined_via,
      'joiner_id', v_user_id,
      'lockout_id', p_lockout_id
    ));
  END IF;

  RETURN json_build_object('success', true);
END;
$$;

-- Also update leave_venue_lockout to dual-write
CREATE OR REPLACE FUNCTION leave_venue_lockout(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
  v_duration_minutes INT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF v_session IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  IF NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'You are not a participant in this lockout');
  END IF;

  -- Remove from array (backwards compat)
  UPDATE lockout_sessions
  SET participants = array_remove(participants, v_user_id)
  WHERE id = p_session_id;

  -- Set left_at on lockout_participants (new)
  UPDATE lockout_participants
  SET left_at = NOW()
  WHERE session_id = p_session_id AND user_id = v_user_id;

  v_duration_minutes := EXTRACT(EPOCH FROM (NOW() - v_session.started_at)) / 60;

  INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score, action_text)
  VALUES (
    v_user_id,
    (v_session.started_at AT TIME ZONE 'UTC')::DATE,
    GREATEST(1, v_duration_minutes),
    COALESCE((SELECT lp.goback_score FROM lockout_participants lp WHERE lp.session_id = p_session_id AND lp.user_id = v_user_id), 0),
    v_session.action_text
  )
  ON CONFLICT (user_id, session_date) DO UPDATE
  SET duration_minutes = lockout_completed_log.duration_minutes + EXCLUDED.duration_minutes,
      goback_score = GREATEST(lockout_completed_log.goback_score, EXCLUDED.goback_score);

  RETURN json_build_object('success', true, 'duration_minutes', v_duration_minutes);
END;
$$;
```

- [ ] **Step 2: Apply migration locally**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && supabase db reset`
Expected: Both functions replaced cleanly.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/*_chain_joining.sql
git commit -m "feat: rewrite join_lockout_session for chain joining with joined_via tracking"
```

---

## Task 3: Update feed and post visibility queries

**Files:**
- Create: `supabase/migrations/YYYYMMDDHHMMSS_lockout_feed_visibility.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- ============================================================================
-- LOCKOUT-BASED FEED VISIBILITY
-- ============================================================================
-- Adds lockout participation as a visibility path for posts.
-- Updates get_user_feed, get_post_by_id, get_post_comments.
-- Adds RLS policies on posts and post_media for lockout participants.
-- ============================================================================

-- 1. New RLS policy: lockout participants can view lockout posts
CREATE POLICY "Users can view lockout posts they participated in"
  ON posts FOR SELECT
  TO authenticated
  USING (
    lockout_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM lockout_participants lp
      WHERE lp.session_id = posts.lockout_id AND lp.user_id = auth.uid()
    )
  );

-- 2. New RLS policy: media viewable via lockout participation
CREATE POLICY "Media viewable via lockout participation"
  ON post_media FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_media.post_id
        AND p.lockout_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM lockout_participants lp
          WHERE lp.session_id = p.lockout_id AND lp.user_id = auth.uid()
        )
    )
  );

-- 3. Update get_user_feed — add lockout-based visibility + per-participant score
DROP FUNCTION IF EXISTS get_user_feed(TIMESTAMPTZ, INT);

CREATE OR REPLACE FUNCTION get_user_feed(
  p_cursor TIMESTAMPTZ DEFAULT NULL,
  p_page_size INT DEFAULT 20
) RETURNS TABLE (
  id UUID,
  author_id UUID,
  author_username TEXT,
  author_avatar_url TEXT,
  lockout_id UUID,
  thumbnail_url TEXT,
  thumbnail_width INT,
  thumbnail_height INT,
  content_type TEXT,
  description TEXT,
  published_at TIMESTAMPTZ,
  published_timezone TEXT,
  calendar_saved_at TIMESTAMPTZ,
  excluded_user_ids UUID[],
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  reaction_count BIGINT,
  comment_count BIGINT,
  video_url TEXT,
  is_author_connected BOOLEAN,
  lockout_score INT,
  lockout_duration_minutes INT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  RETURN QUERY
  WITH my_friends AS (
    SELECT CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id ELSE f.user_a_id END AS friend_id
    FROM friendships f
    WHERE f.user_a_id = v_user_id OR f.user_b_id = v_user_id
  )
  SELECT
    p.id,
    p.author_id,
    prof.username AS author_username,
    prof.avatar_url AS author_avatar_url,
    p.lockout_id,
    p.thumbnail_url,
    p.thumbnail_width,
    p.thumbnail_height,
    p.content_type::TEXT,
    p.description,
    p.published_at,
    p.published_timezone,
    p.calendar_saved_at,
    p.excluded_user_ids,
    p.created_at,
    p.updated_at,
    p.reaction_count::BIGINT,
    -- Per-viewer filtered comment count
    (SELECT COUNT(*) FROM post_comments pc
     WHERE pc.post_id = p.id AND pc.deleted_at IS NULL
       AND (
         pc.author_id = v_user_id
         OR pc.author_id = p.author_id
         OR pc.author_id IN (SELECT mf.friend_id FROM my_friends mf)
       )
    )::BIGINT AS comment_count,
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
    (p.author_id = v_user_id OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)) AS is_author_connected,
    -- Per-participant score (from lockout_participants, not lockout_sessions)
    (SELECT lp.goback_score::INT FROM lockout_participants lp
     WHERE lp.session_id = p.lockout_id AND lp.user_id = p.author_id
     LIMIT 1) AS lockout_score,
    CASE WHEN ls.id IS NOT NULL
      THEN EXTRACT(EPOCH FROM (COALESCE(ls.completed_at, ls.ends_at) - ls.started_at))::INT / 60
      ELSE NULL
    END AS lockout_duration_minutes
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  LEFT JOIN lockout_sessions ls ON p.lockout_id = ls.id
  WHERE
    p.published_at > NOW() - INTERVAL '24 hours'
    AND NOT (v_user_id = ANY(p.excluded_user_ids))
    AND (
      p.author_id = v_user_id
      OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)
      OR (
        p.lockout_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM lockout_participants lp
          WHERE lp.session_id = p.lockout_id AND lp.user_id = v_user_id
        )
      )
    )
    AND (p_cursor IS NULL OR p.published_at < p_cursor)
  ORDER BY p.published_at DESC
  LIMIT p_page_size;
END;
$$;

-- 4. Update get_post_by_id — add lockout visibility + return participant data
DROP FUNCTION IF EXISTS get_post_by_id(UUID);

CREATE OR REPLACE FUNCTION get_post_by_id(p_post_id UUID) RETURNS TABLE (
  id UUID,
  author_id UUID,
  author_username TEXT,
  author_avatar_url TEXT,
  lockout_id UUID,
  thumbnail_url TEXT,
  thumbnail_width INT,
  thumbnail_height INT,
  content_type TEXT,
  description TEXT,
  published_at TIMESTAMPTZ,
  published_timezone TEXT,
  calendar_saved_at TIMESTAMPTZ,
  excluded_user_ids UUID[],
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  reaction_count BIGINT,
  comment_count BIGINT,
  tagged_user_ids UUID[],
  tagged_usernames TEXT[],
  tag_types TEXT[],
  -- NEW: lockout participant arrays
  lockout_participant_ids UUID[],
  lockout_participant_usernames TEXT[],
  lockout_participant_avatars TEXT[],
  lockout_participant_joined_via UUID[]
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_post_author_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Get post author for comment filtering
  SELECT p.author_id INTO v_post_author_id FROM posts p WHERE p.id = p_post_id;

  RETURN QUERY
  WITH my_friends AS (
    SELECT CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id ELSE f.user_a_id END AS friend_id
    FROM friendships f
    WHERE f.user_a_id = v_user_id OR f.user_b_id = v_user_id
  )
  SELECT
    p.id,
    p.author_id,
    prof.username AS author_username,
    prof.avatar_url AS author_avatar_url,
    p.lockout_id,
    p.thumbnail_url,
    p.thumbnail_width,
    p.thumbnail_height,
    p.content_type::TEXT,
    p.description,
    p.published_at,
    p.published_timezone,
    p.calendar_saved_at,
    p.excluded_user_ids,
    p.created_at,
    p.updated_at,
    COALESCE((SELECT COUNT(*) FROM post_reactions pr WHERE pr.post_id = p.id), 0) AS reaction_count,
    -- Per-viewer filtered comment count
    (SELECT COUNT(*) FROM post_comments pc
     WHERE pc.post_id = p.id AND pc.deleted_at IS NULL
       AND (
         pc.author_id = v_user_id
         OR pc.author_id = v_post_author_id
         OR pc.author_id IN (SELECT mf.friend_id FROM my_friends mf)
       )
    )::BIGINT AS comment_count,
    -- Manual mentions only (from post_tags)
    COALESCE((SELECT array_agg(pt.tagged_user_id) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_user_ids,
    COALESCE((SELECT array_agg(pt.username) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_usernames,
    COALESCE((SELECT array_agg(pt.tag_type) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tag_types,
    -- Lockout participants (excluding post author)
    COALESCE((SELECT array_agg(lp.user_id) FROM lockout_participants lp JOIN profiles lpp ON lp.user_id = lpp.id WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id), '{}') AS lockout_participant_ids,
    COALESCE((SELECT array_agg(lpp.username) FROM lockout_participants lp JOIN profiles lpp ON lp.user_id = lpp.id WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id), '{}') AS lockout_participant_usernames,
    COALESCE((SELECT array_agg(lpp.avatar_url) FROM lockout_participants lp JOIN profiles lpp ON lp.user_id = lpp.id WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id), '{}') AS lockout_participant_avatars,
    COALESCE((SELECT array_agg(lp.joined_via) FROM lockout_participants lp JOIN profiles lpp ON lp.user_id = lpp.id WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id), '{}') AS lockout_participant_joined_via
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  WHERE
    p.id = p_post_id
    AND NOT (v_user_id = ANY(p.excluded_user_ids))
    AND (
      p.author_id = v_user_id
      OR EXISTS (
        SELECT 1 FROM friendships f
        WHERE (f.user_a_id = v_user_id AND f.user_b_id = p.author_id)
           OR (f.user_b_id = v_user_id AND f.user_a_id = p.author_id)
      )
      OR (
        p.lockout_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM lockout_participants lp
          WHERE lp.session_id = p.lockout_id AND lp.user_id = v_user_id
        )
      )
    );
END;
$$;

-- 5. Update get_post_comments — per-viewer circle filtering
DROP FUNCTION IF EXISTS get_post_comments(UUID);

CREATE OR REPLACE FUNCTION get_post_comments(p_post_id UUID) RETURNS TABLE (
  id UUID,
  author_id UUID,
  author_username TEXT,
  author_avatar_url TEXT,
  content TEXT,
  created_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_post_author_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Get post author
  SELECT p.author_id INTO v_post_author_id
  FROM posts p
  WHERE p.id = p_post_id;

  -- Verify user can view this post (friendship OR lockout participation)
  IF NOT EXISTS (
    SELECT 1 FROM posts p
    WHERE p.id = p_post_id
      AND NOT (v_user_id = ANY(p.excluded_user_ids))
      AND (
        p.author_id = v_user_id
        OR EXISTS (
          SELECT 1 FROM friendships f
          WHERE (f.user_a_id = v_user_id AND f.user_b_id = p.author_id)
             OR (f.user_b_id = v_user_id AND f.user_a_id = p.author_id)
        )
        OR (
          p.lockout_id IS NOT NULL
          AND EXISTS (
            SELECT 1 FROM lockout_participants lp
            WHERE lp.session_id = p.lockout_id AND lp.user_id = v_user_id
          )
        )
      )
  ) THEN
    RAISE EXCEPTION 'Post not found or access denied';
  END IF;

  RETURN QUERY
  WITH my_friends AS (
    SELECT CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id ELSE f.user_a_id END AS friend_id
    FROM friendships f
    WHERE f.user_a_id = v_user_id OR f.user_b_id = v_user_id
  )
  SELECT
    pc.id,
    pc.author_id,
    prof.username AS author_username,
    prof.avatar_url AS author_avatar_url,
    pc.content,
    pc.created_at,
    pc.deleted_at
  FROM post_comments pc
  JOIN profiles prof ON pc.author_id = prof.id
  WHERE pc.post_id = p_post_id
    AND (
      pc.author_id = v_user_id
      OR pc.author_id = v_post_author_id
      OR pc.author_id IN (SELECT mf.friend_id FROM my_friends mf)
    )
  ORDER BY pc.created_at ASC;
END;
$$;
```

- [ ] **Step 2: Apply migration locally**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && supabase db reset`
Expected: All functions replaced, RLS policies created.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/*_lockout_feed_visibility.sql
git commit -m "feat: add lockout-based feed visibility, per-viewer comment filtering, participant data in post detail"
```

---

## Task 4: Update `get_friends_locked_out` for cross-circle display

**Files:**
- Modify: `supabase/migrations/YYYYMMDDHHMMSS_chain_joining.sql` (or create a new migration)

This can be appended to the chain_joining migration or be its own. For clarity, add to chain_joining migration before committing Task 2, or create a separate migration.

- [ ] **Step 1: Write the RPC update**

```sql
-- ============================================================================
-- Update get_friends_locked_out to show cross-circle participants after joining
-- ============================================================================

DROP FUNCTION IF EXISTS get_friends_locked_out();

CREATE OR REPLACE FUNCTION get_friends_locked_out()
RETURNS TABLE (
  lockout_id UUID,
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  started_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  action_text TEXT,
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  location_name TEXT,
  participants UUID[],
  joined_via UUID
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  RETURN QUERY

  -- Part 1: Friends who OWN active lockouts (I'm NOT a participant)
  SELECT
    ls.id AS lockout_id,
    ls.user_id,
    prof.username,
    prof.avatar_url,
    ls.started_at,
    ls.ends_at,
    ls.action_text,
    ls.location_lat,
    ls.location_lng,
    ls.location_name,
    ls.participants,
    NULL::UUID AS joined_via
  FROM lockout_sessions ls
  JOIN profiles prof ON ls.user_id = prof.id
  WHERE
    (ls.is_open_ended OR ls.ends_at > NOW())
    AND ls.post_id IS NULL
    AND ls.completed_at IS NULL
    AND NOT (v_user_id = ANY(ls.participants))
    AND ls.user_id != v_user_id
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
    )

  UNION

  -- Part 2: Lockout OWNERS of sessions I JOINED (shows me the owner)
  SELECT
    joined_ls.id AS lockout_id,
    joined_ls.user_id,
    owner_prof.username,
    owner_prof.avatar_url,
    joined_ls.started_at,
    joined_ls.ends_at,
    joined_ls.action_text,
    joined_ls.location_lat,
    joined_ls.location_lng,
    joined_ls.location_name,
    joined_ls.participants,
    NULL::UUID AS joined_via
  FROM lockout_sessions joined_ls
  JOIN profiles owner_prof ON joined_ls.user_id = owner_prof.id
  WHERE
    v_user_id = ANY(joined_ls.participants)
    AND (joined_ls.is_open_ended OR joined_ls.ends_at > NOW())
    AND joined_ls.post_id IS NULL
    AND joined_ls.completed_at IS NULL

  UNION

  -- Part 3: ALL co-participants in lockouts I JOINED (cross-circle after joining)
  SELECT
    joined_ls.id AS lockout_id,
    co_participant AS user_id,
    prof.username,
    prof.avatar_url,
    joined_ls.started_at,
    joined_ls.ends_at,
    joined_ls.action_text,
    joined_ls.location_lat,
    joined_ls.location_lng,
    joined_ls.location_name,
    joined_ls.participants,
    lp.joined_via
  FROM lockout_sessions joined_ls
  CROSS JOIN LATERAL unnest(joined_ls.participants) AS co_participant
  JOIN profiles prof ON co_participant = prof.id
  LEFT JOIN lockout_participants lp ON lp.session_id = joined_ls.id AND lp.user_id = co_participant
  WHERE
    v_user_id = ANY(joined_ls.participants)
    AND co_participant != v_user_id
    AND (joined_ls.is_open_ended OR joined_ls.ends_at > NOW())
    AND joined_ls.post_id IS NULL
    AND joined_ls.completed_at IS NULL

  UNION

  -- Part 4: Participants in MY OWN lockout (I'm the owner)
  SELECT
    my_ls.id AS lockout_id,
    participant AS user_id,
    prof.username,
    prof.avatar_url,
    my_ls.started_at,
    my_ls.ends_at,
    my_ls.action_text,
    my_ls.location_lat,
    my_ls.location_lng,
    my_ls.location_name,
    my_ls.participants,
    lp.joined_via
  FROM lockout_sessions my_ls
  CROSS JOIN LATERAL unnest(my_ls.participants) AS participant
  JOIN profiles prof ON participant = prof.id
  LEFT JOIN lockout_participants lp ON lp.session_id = my_ls.id AND lp.user_id = participant
  WHERE
    my_ls.user_id = v_user_id
    AND (my_ls.is_open_ended OR my_ls.ends_at > NOW())
    AND my_ls.post_id IS NULL
    AND my_ls.completed_at IS NULL

  ORDER BY started_at DESC;
END;
$$;
```

- [ ] **Step 2: Apply and test locally**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && supabase db reset`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/*_chain_joining.sql
git commit -m "feat: update get_friends_locked_out for cross-circle participant display with joined_via"
```

---

## Task 5: Lockout notification changes

**Files:**
- Create: `supabase/migrations/YYYYMMDDHHMMSS_lockout_notifications.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- ============================================================================
-- LOCKOUT NOTIFICATIONS
-- ============================================================================
-- 1. New lockout_tag notification type for cross-circle post tags
-- 2. Function to notify lockout participants on post creation
-- 3. Connection request context columns
-- 4. Notification cleanup for expired cross-circle notifications
-- ============================================================================

-- 1. Function to notify lockout participants when a post is created
CREATE OR REPLACE FUNCTION notify_lockout_participants(
  p_post_id UUID,
  p_lockout_id UUID,
  p_author_id UUID
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_participant RECORD;
  v_is_friend BOOLEAN;
  v_is_friend_of_joined_via BOOLEAN;
BEGIN
  FOR v_participant IN
    SELECT lp.user_id, lp.joined_via
    FROM lockout_participants lp
    WHERE lp.session_id = p_lockout_id AND lp.user_id != p_author_id
  LOOP
    -- Check if participant is direct friend of author
    v_is_friend := EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = p_author_id AND f.user_b_id = v_participant.user_id)
         OR (f.user_b_id = p_author_id AND f.user_a_id = v_participant.user_id)
    );

    IF v_is_friend THEN
      -- Distance 1: standard tag notification
      PERFORM upsert_notification(v_participant.user_id, 'tag', p_post_id, p_author_id);
    ELSE
      -- Check distance 2: is the author friends with the participant's joined_via?
      v_is_friend_of_joined_via := v_participant.joined_via IS NOT NULL AND EXISTS (
        SELECT 1 FROM friendships f
        WHERE (f.user_a_id = p_author_id AND f.user_b_id = v_participant.joined_via)
           OR (f.user_b_id = p_author_id AND f.user_a_id = v_participant.joined_via)
      );

      IF v_is_friend_of_joined_via THEN
        -- Distance 2: contextual notification
        PERFORM upsert_notification(v_participant.user_id, 'lockout_tag', p_post_id, p_author_id);
      END IF;
      -- Distance 3+: no notification
    END IF;
  END LOOP;
END;
$$;

-- 2. Connection request context columns
ALTER TABLE connection_requests
ADD COLUMN IF NOT EXISTS context_type TEXT,
ADD COLUMN IF NOT EXISTS context_id UUID;
```

- [ ] **Step 2: Apply migration locally**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && supabase db reset`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/*_lockout_notifications.sql
git commit -m "feat: add lockout participant notifications and connection request context"
```

---

## Task 6: Dart DTO and model for lockout participants

**Files:**
- Create: `lib/core/features/lockout/data/dtos/lockout_participant_dto.dart`
- Create: `lib/core/features/lockout/domain/models/lockout_participant_model.dart`
- Create: `lib/core/features/lockout/domain/utilities/participant_distance.dart`
- Modify: `lib/core/features/lockout/data/dtos/lockout_session_dto.dart`
- Modify: `lib/core/features/lockout/domain/models/lockout_session_model.dart`
- Modify: `lib/core/features/lockout/data/mappers/lockout_session_dto_to_model_mapper.dart`

- [ ] **Step 1: Create `lockout_participant_dto.dart`**

```dart
// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'lockout_participant_dto.freezed.dart';
part 'lockout_participant_dto.g.dart';

@freezed
sealed class LockoutParticipantDto with _$LockoutParticipantDto {
  const factory LockoutParticipantDto({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'joined_via') String? joinedVia,
    @JsonKey(name: 'joined_at') required String joinedAt,
    @JsonKey(name: 'left_at') String? leftAt,
    @JsonKey(name: 'goback_score') int? gobackScore,
    String? username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _LockoutParticipantDto;

  factory LockoutParticipantDto.fromJson(Map<String, dynamic> json) =>
      _$LockoutParticipantDtoFromJson(json);
}
```

- [ ] **Step 2: Create `lockout_participant_model.dart`**

```dart
class LockoutParticipantModel {
  const LockoutParticipantModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.joinedVia,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String? joinedVia;
}
```

- [ ] **Step 3: Create `participant_distance.dart`**

```dart
/// Computes the relationship distance between the current user and a lockout
/// participant using the local friend list and the joined_via chain.
///
/// Distance 1: direct friend
/// Distance 2: friend of joined_via (friend of friend)
/// Distance 3+: no direct path found
class ParticipantDistance {
  const ParticipantDistance._();

  static int compute({
    required String participantId,
    required String? joinedVia,
    required Set<String> myFriendIds,
  }) {
    if (myFriendIds.contains(participantId)) return 1;
    if (joinedVia != null && myFriendIds.contains(joinedVia)) return 2;
    return 3;
  }
}
```

- [ ] **Step 4: Add `joinedVia` to `LockoutSessionDto`**

In `lib/core/features/lockout/data/dtos/lockout_session_dto.dart`, add after the `avatarUrl` field:

```dart
    @JsonKey(name: 'joined_via') String? joinedVia,
```

- [ ] **Step 5: Add `joinedVia` to `LockoutSessionModel`**

In `lib/core/features/lockout/domain/models/lockout_session_model.dart`, add after `avatarUrl`:

```dart
    String? joinedVia,
```

- [ ] **Step 6: Update mapper**

In `lib/core/features/lockout/data/mappers/lockout_session_dto_to_model_mapper.dart`, add `joinedVia: dto.joinedVia` to the model constructor call.

- [ ] **Step 7: Run build_runner**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: All `.freezed.dart` and `.g.dart` files regenerated cleanly.

- [ ] **Step 8: Commit**

```bash
git add lib/core/features/lockout/data/dtos/lockout_participant_dto.dart \
  lib/core/features/lockout/data/dtos/lockout_participant_dto.freezed.dart \
  lib/core/features/lockout/data/dtos/lockout_participant_dto.g.dart \
  lib/core/features/lockout/domain/models/lockout_participant_model.dart \
  lib/core/features/lockout/domain/utilities/participant_distance.dart \
  lib/core/features/lockout/data/dtos/lockout_session_dto.dart \
  lib/core/features/lockout/data/dtos/lockout_session_dto.freezed.dart \
  lib/core/features/lockout/data/dtos/lockout_session_dto.g.dart \
  lib/core/features/lockout/domain/models/lockout_session_model.dart \
  lib/core/features/lockout/domain/models/lockout_session_model.freezed.dart \
  lib/core/features/lockout/domain/models/lockout_session_model.g.dart \
  lib/core/features/lockout/data/mappers/lockout_session_dto_to_model_mapper.dart
git commit -m "feat: add lockout participant DTO, model, distance calculator, and joinedVia field"
```

---

## Task 7: Update `FeedPostModel` with lockout participant data

**Files:**
- Modify: `lib/core/features/post/domain/models/feed_post_model.dart`
- Modify: the feed post DTO/mapper (wherever `FeedPostModel` is constructed from RPC response)

- [ ] **Step 1: Add participant fields to `FeedPostModel`**

Add after `commentCount`:

```dart
    /// Lockout participant user IDs (excluding post author)
    @Default([]) List<String> lockoutParticipantIds,
    /// Lockout participant usernames (parallel to IDs)
    @Default([]) List<String> lockoutParticipantUsernames,
    /// Lockout participant avatar URLs (parallel to IDs)
    @Default([]) List<String?> lockoutParticipantAvatars,
    /// Lockout participant joined_via UUIDs (parallel to IDs, null = direct friend of owner)
    @Default([]) List<String?> lockoutParticipantJoinedVia,
```

- [ ] **Step 2: Update the mapper/DTO that constructs FeedPostModel from the `get_post_by_id` response**

Find where `get_post_by_id` response is parsed and map the new arrays:
- `lockout_participant_ids` → `lockoutParticipantIds`
- `lockout_participant_usernames` → `lockoutParticipantUsernames`
- `lockout_participant_avatars` → `lockoutParticipantAvatars`
- `lockout_participant_joined_via` → `lockoutParticipantJoinedVia`

Note: The feed query (`get_user_feed`) does NOT return participant arrays (too heavy for list view). Participants are only fetched in post detail via `get_post_by_id`.

- [ ] **Step 3: Run build_runner**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/post/
git commit -m "feat: add lockout participant data to FeedPostModel for post detail display"
```

---

## Task 8: Remove participant auto-tagging from post creation

**Files:**
- Modify: `lib/core/features/post/domain/hooks/use_post_creation.dart`

- [ ] **Step 1: Remove participant auto-tagging block**

In `use_post_creation.dart`, replace lines 131-171 (the block that auto-tags lockout participants):

Before:
```dart
            // Auto-tag lockout participants when creating a lockout post
            var finalTaggedUserIds = List<String>.from(
              postCreationData.taggedUserIds,
            );
            String? lockoutOwnerId;
            if (pendingLockoutId != null) {
              final sessionService = ref.read(lockoutSessionServiceProvider);
              final sessionResult = await sessionService.getSessionById(
                pendingLockoutId,
              );
              sessionResult.fold(
                (session) {
                  if (session != null) {
                    lockoutOwnerId = session.userId;
                    // Tag the session owner (if current user is a joiner)
                    if (!finalTaggedUserIds.contains(session.userId) &&
                        session.userId != user.id) {
                      finalTaggedUserIds.add(session.userId);
                      logger.info(
                        'Auto-tagged lockout owner: ${session.userId}',
                      );
                    }
                    // Tag all participants (joiners)
                    for (final participantId in session.participants) {
                      if (!finalTaggedUserIds.contains(participantId) &&
                          participantId != user.id) {
                        finalTaggedUserIds.add(participantId);
                      }
                    }
                    if (session.participants.isNotEmpty) {
                      logger.info(
                        'Auto-tagged ${session.participants.length} lockout participants',
                      );
                    }
                  }
                },
                (error) => logger.warning(
                  'Failed to fetch lockout participants: $error',
                ),
              );
            }
```

After:
```dart
            // Manual @mentions only — lockout participants are derived from
            // lockout_participants table at read time (no auto-tagging needed)
            final finalTaggedUserIds = List<String>.from(
              postCreationData.taggedUserIds,
            );
```

Keep the `lockoutOwnerId` variable if it's used later in the function for `updateSessionPostId`. Check usage — if it's only used for post_id update on the session, fetch it separately:

```dart
            String? lockoutOwnerId;
            if (pendingLockoutId != null) {
              final sessionService = ref.read(lockoutSessionServiceProvider);
              final sessionResult = await sessionService.getSessionById(
                pendingLockoutId,
              );
              sessionResult.fold(
                (session) {
                  if (session != null) {
                    lockoutOwnerId = session.userId;
                  }
                },
                (error) => logger.warning(
                  'Failed to fetch lockout session: $error',
                ),
              );
            }
```

- [ ] **Step 2: Add call to notify lockout participants**

After the post is created successfully (after the `createPostProvider` call), add an RPC call to `notify_lockout_participants`:

```dart
            // Notify lockout participants about the new post
            if (pendingLockoutId != null) {
              try {
                await ref.read(supabaseClientProvider).rpc(
                  'notify_lockout_participants',
                  params: {
                    'p_post_id': result.id,
                    'p_lockout_id': pendingLockoutId,
                    'p_author_id': user.id,
                  },
                );
              } catch (e) {
                logger.warning('Failed to notify lockout participants: $e');
              }
            }
```

- [ ] **Step 3: Verify build compiles**

Run: `fvm flutter analyze`
Expected: No new errors (existing warnings ok per `--no-fatal-warnings`).

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/post/domain/hooks/use_post_creation.dart
git commit -m "feat: remove participant auto-tagging, add lockout post notification"
```

---

## Task 9: Post detail participant display widget

**Files:**
- Create: `lib/presentation/pages/post_detail/components/post_detail_participants.dart`
- Modify: `lib/presentation/pages/post_detail/views/post_detail_overlay.dart`
- Modify: `lib/presentation/pages/post_detail/components/post_detail_tags.dart`

- [ ] **Step 1: Create `post_detail_participants.dart`**

```dart
import 'package:cloudless/core/features/lockout/domain/utilities/participant_distance.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class PostDetailParticipants extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailParticipants({
    required this.participantIds,
    required this.participantUsernames,
    required this.participantAvatars,
    required this.participantJoinedVia,
    required this.myFriendIds,
    this.onFriendTap,
    this.onFriendOfFriendTap,
    super.key,
  });

  final List<String> participantIds;
  final List<String> participantUsernames;
  final List<String?> participantAvatars;
  final List<String?> participantJoinedVia;
  final Set<String> myFriendIds;
  final void Function(String userId, String username)? onFriendTap;
  final void Function(String userId, String username, String? lockoutId)?
      onFriendOfFriendTap;

  @override
  Widget build(BuildContext context) {
    if (participantIds.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final distance1 = <int>[];
    final distance2 = <int>[];
    var distance3Count = 0;

    for (var i = 0; i < participantIds.length; i++) {
      final d = ParticipantDistance.compute(
        participantId: participantIds[i],
        joinedVia: i < participantJoinedVia.length
            ? participantJoinedVia[i]
            : null,
        myFriendIds: myFriendIds,
      );
      if (d == 1) {
        distance1.add(i);
      } else if (d == 2) {
        distance2.add(i);
      } else {
        distance3Count++;
      }
    }

    final children = <Widget>[];

    // Distance 1: @username (tappable)
    for (final i in distance1) {
      final isLast =
          distance2.isEmpty && distance3Count == 0 && i == distance1.last;
      children.add(
        GestureDetector(
          onTap: () => onFriendTap?.call(
            participantIds[i],
            participantUsernames[i],
          ),
          child: Text(
            '@${participantUsernames[i]}${isLast ? '' : ','}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outlineVariant,
              fontWeight: FontWeight.w500,
              height: 20.5 / 14.0,
            ),
          ),
        ),
      );
    }

    // Distance 2: @username · friend of @X (tappable)
    for (final i in distance2) {
      final joinedViaId = participantJoinedVia[i];
      // Find the joined_via username from the participant list or friend list
      String? joinedViaUsername;
      if (joinedViaId != null) {
        final jvIndex = participantIds.indexOf(joinedViaId);
        if (jvIndex >= 0) {
          joinedViaUsername = participantUsernames[jvIndex];
        }
      }

      final isLast = distance3Count == 0 && i == distance2.last;
      final label = joinedViaUsername != null
          ? '@${participantUsernames[i]} · friend of @$joinedViaUsername'
          : '@${participantUsernames[i]}';

      children.add(
        GestureDetector(
          onTap: () => onFriendOfFriendTap?.call(
            participantIds[i],
            participantUsernames[i],
            null,
          ),
          child: Text(
            '$label${isLast ? '' : ','}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              height: 20.5 / 14.0,
            ),
          ),
        ),
      );
    }

    // Distance 3+: "and N others"
    if (distance3Count > 0) {
      children.add(
        Text(
          'and $distance3Count other${distance3Count == 1 ? '' : 's'}',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 20.5 / 14.0,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Assets.svg.tag.render(),
        SizedBox(width: tagSpacing),
        Expanded(
          child: Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: children,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Integrate into post detail overlay**

In `post_detail_overlay.dart`, add `PostDetailParticipants` below the existing `PostDetailTags` widget when the post has a `lockoutId`. The existing `PostDetailTags` now only shows manual @mentions. The new `PostDetailParticipants` shows lockout participants with distance tiers.

Wire up the `myFriendIds` from the circle members provider that already exists for mention autocomplete.

- [ ] **Step 3: Verify build compiles**

Run: `fvm flutter analyze`

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/post_detail/components/post_detail_participants.dart \
  lib/presentation/pages/post_detail/views/post_detail_overlay.dart
git commit -m "feat: add tiered participant display widget for post detail"
```

---

## Task 10: Update friends locked out UI for cross-circle display

**Files:**
- Modify: `lib/core/features/lockout/data/dtos/lockout_session_dto.dart` (already done in Task 6)
- Modify: `lib/presentation/pages/manual_lockout/components/friend_locked_out_item.dart`
- Modify: `lib/presentation/pages/manual_lockout/components/friends_locked_out_list.dart`

- [ ] **Step 1: Update `FriendLockedOutItem` to show distance tier labels**

Add a `distance` parameter and show "friend of @X" subtitle for distance 2, or collapse for distance 3+:

```dart
class FriendLockedOutItem extends StatelessWidget {
  const FriendLockedOutItem({
    super.key,
    required this.session,
    required this.onTap,
    this.isInSameLockout = false,
    this.distance = 1,
    this.joinedViaUsername,
  });

  final LockoutSessionModel session;
  final VoidCallback onTap;
  final bool isInSameLockout;
  final int distance;
  final String? joinedViaUsername;
  // ... rest of build method adds subtitle for distance 2
```

In the `Column` children, after the username `Text` widget, add:

```dart
                if (distance == 2 && joinedViaUsername != null) ...[
                  Text(
                    'via @$joinedViaUsername',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.surface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
```

- [ ] **Step 2: Update `FriendsLockedOutList` to compute distances and handle collapsed items**

In `_buildList`, compute distance for each session using `ParticipantDistance.compute` and the user's friend list. Group distance 3+ into a single "and N others" item at the end.

- [ ] **Step 3: Verify build compiles**

Run: `fvm flutter analyze`

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/manual_lockout/components/friend_locked_out_item.dart \
  lib/presentation/pages/manual_lockout/components/friends_locked_out_list.dart
git commit -m "feat: show distance tier labels in friends locked out list"
```

---

## Task 11: Limited profile view + share card update

**Files:**
- Create: `lib/presentation/pages/profile/views/limited_profile_view.dart`
- Modify: `lib/presentation/components/share_card/share_post_dialog.dart`
- Modify: `lib/core/features/connection/data/services/connection_service.dart`

- [ ] **Step 1: Create `limited_profile_view.dart`**

A simple screen showing username, avatar, and "Add to circle" button. Navigated to when tapping a distance-2 participant in post detail or friends-locked-out list.

```dart
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class LimitedProfileView extends HookConsumerWidget {
  const LimitedProfileView({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.contextType,
    this.contextId,
    super.key,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String? contextType;
  final String? contextId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileImage(
              imageUrl: avatarUrl,
              username: username,
              size: 120,
              showFromProfile: false,
              isEditable: false,
            ),
            const SizedBox(height: 16),
            Text(
              '@$username',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _sendConnectionRequest(context, ref),
              child: const Text('Add to circle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendConnectionRequest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Call connection service with context params
    // Show success/error snackbar
    // Pop back on success
  }
}
```

- [ ] **Step 2: Update share card**

In `share_post_dialog.dart`, when `post.lockoutId != null`, replace tagged usernames display with:

```dart
'Locked out with ${post.lockoutParticipantIds.length} other${post.lockoutParticipantIds.length == 1 ? '' : 's'}'
```

- [ ] **Step 3: Add context params to connection service**

In `connection_service.dart`, update `sendConnectionRequest` to accept optional `contextType` and `contextId` and pass them to the RPC.

- [ ] **Step 4: Verify build compiles**

Run: `fvm flutter analyze`

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/profile/views/limited_profile_view.dart \
  lib/presentation/components/share_card/share_post_dialog.dart \
  lib/core/features/connection/data/services/connection_service.dart
git commit -m "feat: add limited profile view, update share card for lockout posts, add connection context"
```

---

## Task 12: Push migration to staging and update tracking

**Files:**
- Modify: `memory/project_stage_migrations.md`

- [ ] **Step 1: Push all new migrations to staging Supabase**

Run each migration against the staging Supabase instance using the Supabase dashboard SQL editor or `supabase db push`.

- [ ] **Step 2: Update migration tracking**

Add all new migrations to `memory/project_stage_migrations.md`:
- `lockout_participants`
- `chain_joining`
- `lockout_feed_visibility`
- `lockout_notifications`

- [ ] **Step 3: Smoke test on staging**

Verify:
1. Creating a lockout inserts owner row into `lockout_participants`
2. Joining a lockout (as friend of participant) works via chain joining
3. `get_friends_locked_out` returns `joined_via` for co-participants
4. Creating a post from lockout shows per-participant score
5. Feed shows cross-circle lockout posts

- [ ] **Step 4: Commit tracking update**

```bash
git add memory/project_stage_migrations.md
git commit -m "docs: track cross-circle tagging migrations on staging"
```
