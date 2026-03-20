-- ============================================================================
-- SQL CHANGELOG - Applied Changes Tracker
-- ============================================================================
-- Run each APPLY block in order against your Supabase SQL Editor.
-- If you need to undo a change, run its REVERT block.
-- Always revert in REVERSE order (latest first).
-- ============================================================================


-- ############################################################################
-- CHANGE 001: Migration 006 - Tagging System Rework
-- Applied to: stage
-- Date: 2026-02-10
-- Source: db/migrations/006_tagging_system_rework.sql
-- ############################################################################

-- ===== APPLY =====

-- Add tag_type column to post_tags
ALTER TABLE post_tags ADD COLUMN IF NOT EXISTS tag_type TEXT DEFAULT 'mention';

-- Update existing lockout-based tags to 'participant'
UPDATE post_tags
SET tag_type = 'participant'
WHERE post_id IN (
  SELECT p.id FROM posts p WHERE p.lockout_id IS NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_post_tags_type ON post_tags (post_id, tag_type);

-- Create comment_mentions table
CREATE TABLE IF NOT EXISTS comment_mentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES post_comments(id) ON DELETE CASCADE,
  mentioned_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_comment_mention UNIQUE (comment_id, mentioned_user_id)
);

CREATE INDEX IF NOT EXISTS idx_comment_mentions_comment ON comment_mentions (comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_mentions_user ON comment_mentions (mentioned_user_id);

-- RLS for comment_mentions
ALTER TABLE comment_mentions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mentions viewable via comment access"
  ON comment_mentions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM post_comments pc
      JOIN posts p ON pc.post_id = p.id
      WHERE pc.id = comment_mentions.comment_id
        AND (
          p.author_id = auth.uid()
          OR (
            NOT (auth.uid() = ANY(p.excluded_user_ids))
            AND EXISTS (
              SELECT 1 FROM friendships f
              WHERE (f.user_a_id = auth.uid() AND f.user_b_id = p.author_id)
                 OR (f.user_b_id = auth.uid() AND f.user_a_id = p.author_id)
            )
          )
        )
    )
  );

-- Notification trigger for comment mentions
CREATE OR REPLACE FUNCTION trigger_notification_on_comment_mention()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_comment_author_id UUID;
  v_post_id UUID;
BEGIN
  SELECT author_id, post_id INTO v_comment_author_id, v_post_id
  FROM post_comments
  WHERE id = NEW.comment_id;

  PERFORM upsert_notification(
    NEW.mentioned_user_id,
    'mention',
    v_post_id,
    v_comment_author_id
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notification_on_comment_mention
  AFTER INSERT ON comment_mentions
  FOR EACH ROW EXECUTE FUNCTION trigger_notification_on_comment_mention();

-- Updated get_post_by_id with tag_type support
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
  tag_types TEXT[]
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
    COALESCE((SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id AND pc.deleted_at IS NULL), 0) AS comment_count,
    COALESCE((SELECT array_agg(pt.tagged_user_id) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_user_ids,
    COALESCE((SELECT array_agg(pt.username) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_usernames,
    COALESCE((SELECT array_agg(pt.tag_type) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tag_types
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
    );
END;
$$;

-- RPC to add post tags with type
CREATE OR REPLACE FUNCTION add_post_tag(
  p_post_id UUID,
  p_tagged_user_id UUID,
  p_tag_type TEXT DEFAULT 'mention'
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_post RECORD;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  SELECT * INTO v_post FROM posts WHERE id = p_post_id;

  IF v_post IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Post not found');
  END IF;

  IF v_post.author_id != v_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Not authorized to tag on this post');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = v_user_id AND f.user_b_id = p_tagged_user_id)
       OR (f.user_b_id = v_user_id AND f.user_a_id = p_tagged_user_id)
  ) THEN
    RETURN json_build_object('success', false, 'error', 'Can only tag friends');
  END IF;

  INSERT INTO post_tags (post_id, tagged_user_id, tag_type)
  VALUES (p_post_id, p_tagged_user_id, p_tag_type)
  ON CONFLICT (post_id, tagged_user_id) DO UPDATE SET tag_type = p_tag_type;

  RETURN json_build_object('success', true);
END;
$$;

-- RPC to add comment mentions
CREATE OR REPLACE FUNCTION add_comment_mentions(
  p_comment_id UUID,
  p_mentioned_user_ids UUID[]
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_comment RECORD;
  v_post RECORD;
  v_mentioned_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  SELECT * INTO v_comment FROM post_comments WHERE id = p_comment_id;

  IF v_comment IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Comment not found');
  END IF;

  IF v_comment.author_id != v_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Not authorized');
  END IF;

  SELECT * INTO v_post FROM posts WHERE id = v_comment.post_id;

  FOREACH v_mentioned_id IN ARRAY p_mentioned_user_ids
  LOOP
    IF EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = v_mentioned_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = v_mentioned_id)
    ) THEN
      INSERT INTO comment_mentions (comment_id, mentioned_user_id)
      VALUES (p_comment_id, v_mentioned_id)
      ON CONFLICT (comment_id, mentioned_user_id) DO NOTHING;
    END IF;
  END LOOP;

  RETURN json_build_object('success', true);
END;
$$;

-- RPC to get user profile with connection status
CREATE OR REPLACE FUNCTION get_profile_with_connection_status(
  p_user_id UUID
) RETURNS TABLE (
  id UUID,
  username TEXT,
  biography TEXT,
  avatar_url TEXT,
  weekly_lockout_minutes INT,
  is_friend BOOLEAN,
  is_self BOOLEAN
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
  SELECT
    p.id,
    p.username,
    p.biography,
    p.avatar_url,
    p.weekly_lockout_minutes,
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = p_user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = p_user_id)
    ) AS is_friend,
    (v_user_id = p_user_id) AS is_self
  FROM profiles p
  WHERE p.id = p_user_id;
END;
$$;

-- ===== REVERT 001 =====
-- Run these in order to undo Change 001:
--
-- DROP FUNCTION IF EXISTS get_profile_with_connection_status(UUID);
-- DROP FUNCTION IF EXISTS add_comment_mentions(UUID, UUID[]);
-- DROP FUNCTION IF EXISTS add_post_tag(UUID, UUID, TEXT);
-- DROP FUNCTION IF EXISTS get_post_by_id(UUID);
-- DROP TRIGGER IF EXISTS trg_notification_on_comment_mention ON comment_mentions;
-- DROP FUNCTION IF EXISTS trigger_notification_on_comment_mention();
-- DROP POLICY IF EXISTS "Mentions viewable via comment access" ON comment_mentions;
-- DROP TABLE IF EXISTS comment_mentions;
-- DROP INDEX IF EXISTS idx_post_tags_type;
-- ALTER TABLE post_tags DROP COLUMN IF EXISTS tag_type;
--
-- NOTE: You will also need to restore the original get_post_by_id function
-- from db/migrations/005_lockout_calendar.sql or earlier.


-- ############################################################################
-- CHANGE 002: Migration 007 - Calendar "Most Memorable" Selection
-- Applied to: stage
-- Date: 2026-02-10
-- Source: db/migrations/007_calendar_memorable_selection.sql
-- ############################################################################

-- ===== APPLY =====

CREATE OR REPLACE FUNCTION get_pending_selection_posts(
  p_date DATE DEFAULT NULL
) RETURNS TABLE (
  id UUID,
  author_id UUID,
  thumbnail_url TEXT,
  thumbnail_width INT,
  thumbnail_height INT,
  content_type TEXT,
  description TEXT,
  published_at TIMESTAMPTZ,
  published_timezone TEXT,
  lockout_id UUID
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_target_date DATE;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  v_target_date := COALESCE(p_date, CURRENT_DATE - INTERVAL '1 day');

  RETURN QUERY
  SELECT
    p.id,
    p.author_id,
    p.thumbnail_url,
    p.thumbnail_width,
    p.thumbnail_height,
    p.content_type::TEXT,
    p.description,
    p.published_at,
    p.published_timezone,
    p.lockout_id
  FROM posts p
  WHERE
    p.author_id = v_user_id
    AND p.calendar_saved_at IS NULL
    AND p.lockout_id IS NOT NULL
    AND DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = v_target_date
    AND p.published_at > NOW() - INTERVAL '24 hours'
  ORDER BY p.published_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION unsave_post_from_calendar(p_post_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_post RECORD;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  SELECT * INTO v_post FROM posts WHERE id = p_post_id;

  IF v_post IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Post not found');
  END IF;

  IF v_post.author_id != v_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Cannot unsave other users posts');
  END IF;

  IF v_post.calendar_saved_at IS NULL THEN
    RETURN json_build_object('success', true, 'message', 'Post is not saved to calendar');
  END IF;

  UPDATE posts SET calendar_saved_at = NULL WHERE id = p_post_id;

  RETURN json_build_object('success', true, 'message', 'Post removed from calendar');
END;
$$;

DROP FUNCTION IF EXISTS get_user_lockout_calendar(UUID, INT, INT);

CREATE OR REPLACE FUNCTION get_user_lockout_calendar(
  p_target_user_id UUID,
  p_year INT,
  p_month INT,
  p_saved_only BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
  post_id UUID,
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
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  tagged_usernames TEXT,
  tagged_user_ids TEXT,
  excluded_user_ids UUID[],
  is_author_connected BOOLEAN,
  is_own_post BOOLEAN,
  video_url TEXT
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

  IF p_target_user_id != v_user_id THEN
    IF NOT EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = p_target_user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = p_target_user_id)
    ) THEN
      RAISE EXCEPTION 'Cannot view calendar of non-friend';
    END IF;
  END IF;

  RETURN QUERY
  SELECT
    p.id AS post_id,
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
    p.created_at,
    p.updated_at,
    (SELECT STRING_AGG(pt.username, ',') FROM post_tags pt WHERE pt.post_id = p.id) AS tagged_usernames,
    (SELECT STRING_AGG(pt.tagged_user_id::TEXT, ',') FROM post_tags pt WHERE pt.post_id = p.id) AS tagged_user_ids,
    p.excluded_user_ids,
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = p.author_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = p.author_id)
    ) AS is_author_connected,
    (p.author_id = v_user_id) AS is_own_post,
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  WHERE
    p.author_id = p_target_user_id
    AND p.lockout_id IS NOT NULL
    AND EXTRACT(YEAR FROM p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = p_year
    AND EXTRACT(MONTH FROM p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = p_month
    AND (p_target_user_id = v_user_id OR NOT (v_user_id = ANY(p.excluded_user_ids)))
    AND (NOT p_saved_only OR p.calendar_saved_at IS NOT NULL)
  ORDER BY p.published_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION has_pending_selection(
  p_date DATE DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_target_date DATE;
  v_count INT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  v_target_date := COALESCE(p_date, CURRENT_DATE - INTERVAL '1 day');

  SELECT COUNT(*) INTO v_count
  FROM posts p
  WHERE
    p.author_id = v_user_id
    AND p.calendar_saved_at IS NULL
    AND p.lockout_id IS NOT NULL
    AND DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = v_target_date
    AND p.published_at > NOW() - INTERVAL '24 hours';

  RETURN v_count > 0;
END;
$$;

-- ===== REVERT 002 =====
-- Run these in order to undo Change 002:
--
-- DROP FUNCTION IF EXISTS has_pending_selection(DATE);
-- DROP FUNCTION IF EXISTS get_user_lockout_calendar(UUID, INT, INT, BOOLEAN);
-- DROP FUNCTION IF EXISTS unsave_post_from_calendar(UUID);
-- DROP FUNCTION IF EXISTS get_pending_selection_posts(DATE);
--
-- NOTE: You will need to restore the original get_user_lockout_calendar(UUID, INT, INT)
-- from db/migrations/005_lockout_calendar.sql.


-- ############################################################################
-- CHANGE 003: Migration 008 - Push Notifications (Device Tokens)
-- Applied to: stage
-- Date: 2026-02-10
-- Source: db/migrations/008_push_notifications.sql
-- ############################################################################

-- ===== APPLY =====

CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_token UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens (user_id);

CREATE TRIGGER trg_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own device tokens"
  ON device_tokens FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own device tokens"
  ON device_tokens FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own device tokens"
  ON device_tokens FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own device tokens"
  ON device_tokens FOR DELETE
  USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION register_device_token(
  p_token TEXT,
  p_platform TEXT
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  INSERT INTO device_tokens (user_id, token, platform)
  VALUES (v_user_id, p_token, p_platform)
  ON CONFLICT (user_id, token) DO UPDATE SET
    platform = p_platform,
    updated_at = NOW();

  RETURN json_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION unregister_device_token(
  p_token TEXT
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  DELETE FROM device_tokens
  WHERE user_id = v_user_id AND token = p_token;

  RETURN json_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION get_friend_device_tokens_for_lockout(
  p_lockout_user_id UUID
) RETURNS TABLE (
  user_id UUID,
  token TEXT,
  platform TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    dt.user_id,
    dt.token,
    dt.platform
  FROM device_tokens dt
  WHERE
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = p_lockout_user_id AND f.user_b_id = dt.user_id)
         OR (f.user_b_id = p_lockout_user_id AND f.user_a_id = dt.user_id)
    )
    AND NOT EXISTS (
      SELECT 1 FROM lockout_sessions ls
      WHERE ls.user_id = dt.user_id
        AND ls.ends_at > NOW()
        AND ls.post_id IS NULL
    );
END;
$$;

CREATE OR REPLACE FUNCTION is_lockout_joinable(
  p_lockout_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ends_at TIMESTAMPTZ;
  v_post_id UUID;
BEGIN
  SELECT ends_at, post_id INTO v_ends_at, v_post_id
  FROM lockout_sessions
  WHERE id = p_lockout_id;

  IF v_ends_at IS NULL THEN
    RETURN FALSE;
  END IF;

  IF v_post_id IS NOT NULL THEN
    RETURN FALSE;
  END IF;

  RETURN v_ends_at > NOW() + INTERVAL '30 minutes';
END;
$$;

-- ===== REVERT 003 =====
-- Run these in order to undo Change 003:
--
-- DROP FUNCTION IF EXISTS is_lockout_joinable(UUID);
-- DROP FUNCTION IF EXISTS get_friend_device_tokens_for_lockout(UUID);
-- DROP FUNCTION IF EXISTS unregister_device_token(TEXT);
-- DROP FUNCTION IF EXISTS register_device_token(TEXT, TEXT);
-- DROP POLICY IF EXISTS "Users can delete own device tokens" ON device_tokens;
-- DROP POLICY IF EXISTS "Users can update own device tokens" ON device_tokens;
-- DROP POLICY IF EXISTS "Users can insert own device tokens" ON device_tokens;
-- DROP POLICY IF EXISTS "Users can view own device tokens" ON device_tokens;
-- DROP TRIGGER IF EXISTS trg_device_tokens_updated_at ON device_tokens;
-- DROP TABLE IF EXISTS device_tokens;


-- ############################################################################
-- CHANGE 004: Migration 009 - Notification System Redesign
-- Applied to: stage
-- Date: 2026-02-10
-- Source: db/migrations/009_notification_system_redesign.sql
-- ############################################################################

-- ===== APPLY =====

DROP FUNCTION IF EXISTS get_notification_feed();

CREATE OR REPLACE FUNCTION get_notification_feed() RETURNS TABLE (
  id UUID,
  type TEXT,
  reference_id UUID,
  latest_actor_id UUID,
  latest_actor_username TEXT,
  latest_actor_avatar TEXT,
  actor_count INT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_three_days_ago TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  UPDATE profiles SET notifications_checked_at = NOW() WHERE id = v_user_id;

  v_three_days_ago := NOW() - INTERVAL '3 days';

  RETURN QUERY
  SELECT
    n.id,
    n.type,
    n.reference_id,
    n.latest_actor_id,
    actor.username AS latest_actor_username,
    actor.avatar_url AS latest_actor_avatar,
    n.actor_count,
    n.created_at,
    n.updated_at,
    n.read_at
  FROM notifications n
  LEFT JOIN profiles actor ON n.latest_actor_id = actor.id
  WHERE n.user_id = v_user_id
    AND (
      (n.type IN ('reaction', 'comment', 'tag', 'mention') AND n.updated_at > v_three_days_ago)
      OR n.type IN ('lockout_started', 'lockout_joined', 'friend_joined')
    )
  ORDER BY n.updated_at DESC
  LIMIT 50;
END;
$$;

CREATE OR REPLACE FUNCTION cleanup_old_activity_notifications() RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted_count INT;
  v_cutoff TIMESTAMPTZ;
BEGIN
  v_cutoff := NOW() - INTERVAL '3 days';

  DELETE FROM notifications
  WHERE type IN ('reaction', 'comment', 'tag', 'mention')
    AND updated_at < v_cutoff;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  RETURN json_build_object(
    'success', true,
    'deleted_count', v_deleted_count,
    'cutoff_time', v_cutoff,
    'executed_at', NOW()
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_joinable_friend_lockouts() RETURNS TABLE (
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
  minutes_remaining INT,
  is_joinable BOOLEAN
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
    EXTRACT(EPOCH FROM (ls.ends_at - NOW()))::INT / 60 AS minutes_remaining,
    (ls.ends_at > NOW() + INTERVAL '30 minutes') AS is_joinable
  FROM lockout_sessions ls
  JOIN profiles prof ON ls.user_id = prof.id
  WHERE
    ls.ends_at > NOW()
    AND ls.post_id IS NULL
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
    )
  ORDER BY ls.started_at DESC;
END;
$$;

-- ===== REVERT 004 =====
-- Run these in order to undo Change 004:
--
-- DROP FUNCTION IF EXISTS get_joinable_friend_lockouts();
-- DROP FUNCTION IF EXISTS cleanup_old_activity_notifications();
-- DROP FUNCTION IF EXISTS get_notification_feed();
--
-- NOTE: You will need to restore the original get_notification_feed()
-- from db/migrations/001_schema_v2.sql.


-- ############################################################################
-- CHANGE 005: Bugfix - Mention notification aggregation
-- Applied to: stage
-- Date: 2026-02-10
-- Description: trigger_notification_on_comment_mention was using comment_id
--   as reference_id, causing a new notification row per comment instead of
--   aggregating by post. Fixed to use post_id.
-- ############################################################################

-- ===== APPLY =====

CREATE OR REPLACE FUNCTION trigger_notification_on_comment_mention()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_comment_author_id UUID;
  v_post_id UUID;
BEGIN
  SELECT author_id, post_id INTO v_comment_author_id, v_post_id
  FROM post_comments
  WHERE id = NEW.comment_id;

  PERFORM upsert_notification(
    NEW.mentioned_user_id,
    'mention',
    v_post_id,
    v_comment_author_id
  );

  RETURN NEW;
END;
$$;

-- Clean up duplicate notification rows created by the bug.
-- Keeps the most recently updated row per (user_id, type, reference_id=post_id)
-- and deletes the rest.
-- NOTE: Only run this if you had the buggy trigger active and created
-- duplicate mention notifications. Inspect first with:
--   SELECT * FROM notifications WHERE type = 'mention' ORDER BY user_id, updated_at DESC;

-- ===== REVERT 005 =====
-- Reverts to the buggy version (not recommended, listed for completeness):
--
-- CREATE OR REPLACE FUNCTION trigger_notification_on_comment_mention()
-- RETURNS TRIGGER
-- LANGUAGE plpgsql SECURITY DEFINER
-- AS $$
-- DECLARE
--   v_comment_author_id UUID;
-- BEGIN
--   SELECT author_id INTO v_comment_author_id
--   FROM post_comments
--   WHERE id = NEW.comment_id;
--
--   PERFORM upsert_notification(
--     NEW.mentioned_user_id,
--     'mention',
--     NEW.comment_id,
--     v_comment_author_id
--   );
--
--   RETURN NEW;
-- END;
-- $$;


-- ############################################################################
-- CHANGE 006: Cleanup mentions and notifications on comment soft-delete
-- Applied to: stage
-- Date: 2026-02-10
-- Description: When a comment is soft-deleted, clean up its comment_mentions
--   rows and decrement/remove the corresponding mention notifications.
--   Mirrors Twitter behavior: deleting content removes its notifications.
-- ############################################################################

-- ===== APPLY =====

CREATE OR REPLACE FUNCTION trigger_cleanup_on_comment_soft_delete()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_mention RECORD;
BEGIN
  -- For each mention in this comment, decrement the notification actor_count
  FOR v_mention IN
    SELECT cm.mentioned_user_id
    FROM comment_mentions cm
    WHERE cm.comment_id = NEW.id
  LOOP
    UPDATE notifications
    SET actor_count = actor_count - 1,
        updated_at = NOW()
    WHERE user_id = v_mention.mentioned_user_id
      AND type = 'mention'
      AND reference_id = NEW.post_id;
  END LOOP;

  -- Delete notifications where actor_count dropped to 0 or below
  DELETE FROM notifications
  WHERE type = 'mention'
    AND reference_id = NEW.post_id
    AND actor_count <= 0;

  -- Clean up the mention records
  DELETE FROM comment_mentions WHERE comment_id = NEW.id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cleanup_on_comment_soft_delete
  AFTER UPDATE ON post_comments
  FOR EACH ROW
  WHEN (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL)
  EXECUTE FUNCTION trigger_cleanup_on_comment_soft_delete();

-- ===== REVERT 006 =====
-- Run these to undo Change 006:
--
-- DROP TRIGGER IF EXISTS trg_cleanup_on_comment_soft_delete ON post_comments;
-- DROP FUNCTION IF EXISTS trigger_cleanup_on_comment_soft_delete();


-- ############################################################################
-- CHANGE 007: Bugfix - Ambiguous column reference in get_notification_feed
-- Applied to: stage
-- Date: 2026-02-10
-- Description: RETURNS TABLE output parameter names (id, type, etc.) clashed
--   with table column names in the query body. Added #variable_conflict
--   use_column directive to resolve in favor of table columns.
-- ############################################################################

-- ===== APPLY =====
-- (Replaces the get_notification_feed from Change 004 with the directive fix)

CREATE OR REPLACE FUNCTION get_notification_feed() RETURNS TABLE (
  id UUID,
  type TEXT,
  reference_id UUID,
  latest_actor_id UUID,
  latest_actor_username TEXT,
  latest_actor_avatar TEXT,
  actor_count INT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
  v_user_id UUID;
  v_three_days_ago TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  UPDATE profiles SET notifications_checked_at = NOW() WHERE id = v_user_id;

  v_three_days_ago := NOW() - INTERVAL '3 days';

  RETURN QUERY
  SELECT
    n.id,
    n.type,
    n.reference_id,
    n.latest_actor_id,
    actor.username AS latest_actor_username,
    actor.avatar_url AS latest_actor_avatar,
    n.actor_count,
    n.created_at,
    n.updated_at,
    n.read_at
  FROM notifications n
  LEFT JOIN profiles actor ON n.latest_actor_id = actor.id
  WHERE n.user_id = v_user_id
    AND (
      (n.type IN ('reaction', 'comment', 'tag', 'mention') AND n.updated_at > v_three_days_ago)
      OR n.type IN ('lockout_started', 'lockout_joined', 'friend_joined')
    )
  ORDER BY n.updated_at DESC
  LIMIT 50;
END;
$$;

-- ===== REVERT 007 =====
-- Reverts to the version without the directive (will re-introduce the bug):
-- Re-run the APPLY block from Change 004 without #variable_conflict.


-- ############################################################################
-- CHANGE 008: Migration 015 - Activity Stats for Hobbies Bubble Cloud
-- Applied to: stage
-- Date: 2026-03-19
-- Source: db/migrations/015_activity_stats.sql
-- ############################################################################

-- ===== APPLY =====

ALTER TABLE lockout_completed_log ADD COLUMN action_text TEXT;

-- Patch complete_lockout_session to persist action_text in the log
-- (full function body in db/migrations/015_activity_stats.sql section 2)

-- Patch update_lockout_weekly_stats to persist action_text in the log
-- (full function body in db/migrations/015_activity_stats.sql section 3)

-- New RPC: get_lockout_activity_stats
CREATE OR REPLACE FUNCTION get_lockout_activity_stats(p_user_id UUID)
RETURNS TABLE(action_text TEXT, total_minutes INT, session_count INT)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
  v_cutoff DATE := (CURRENT_DATE - INTERVAL '27 days')::date;
BEGIN
  RETURN QUERY
  SELECT
    l.action_text,
    COALESCE(SUM(l.duration_minutes), 0)::int AS total_minutes,
    COUNT(*)::int AS session_count
  FROM lockout_completed_log l
  WHERE l.user_id = p_user_id
    AND l.session_date >= v_cutoff
    AND l.action_text IS NOT NULL
  GROUP BY l.action_text
  ORDER BY total_minutes DESC;
END;
$$;

-- ===== REVERT 008 =====
-- Run these in order to undo Change 008:
--
-- DROP FUNCTION IF EXISTS get_lockout_activity_stats(UUID);
-- ALTER TABLE lockout_completed_log DROP COLUMN IF EXISTS action_text;
--
-- NOTE: You will need to restore complete_lockout_session and
-- update_lockout_weekly_stats from db/migrations/013_lockout_stats.sql.
