-- ============================================================================
-- GOBACK DATABASE SCHEMA V2 - FRESH INSTALL
-- ============================================================================
-- Run this on a blank Supabase project to set up the complete schema
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ============================================================================
-- TYPES
-- ============================================================================

CREATE TYPE content_type AS ENUM ('image', 'video');

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. profiles
-- ----------------------------------------------------------------------------
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  biography TEXT,
  avatar_url TEXT,
  weekly_lockout_minutes INT DEFAULT 0,
  notifications_checked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT username_length CHECK (char_length(username) <= 30),
  CONSTRAINT bio_length CHECK (biography IS NULL OR char_length(biography) <= 200)
);

CREATE UNIQUE INDEX profiles_username_unique_ci ON profiles (LOWER(username));

-- ----------------------------------------------------------------------------
-- 2. friendships
-- ----------------------------------------------------------------------------
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT friendship_ordered CHECK (user_a_id < user_b_id),
  CONSTRAINT friendship_unique UNIQUE (user_a_id, user_b_id)
);

CREATE INDEX idx_friendships_user_a ON friendships (user_a_id);
CREATE INDEX idx_friendships_user_b ON friendships (user_b_id);

-- ----------------------------------------------------------------------------
-- 3. invite_codes
-- ----------------------------------------------------------------------------
CREATE TABLE invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  used_by_id UUID REFERENCES profiles(id),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  used_at TIMESTAMPTZ
);

CREATE INDEX idx_invite_codes_creator ON invite_codes (creator_id);
CREATE INDEX idx_invite_codes_expires ON invite_codes (expires_at);
CREATE INDEX idx_invite_codes_code ON invite_codes (code);

-- ----------------------------------------------------------------------------
-- 4. lockout_sessions
-- ----------------------------------------------------------------------------
CREATE TABLE lockout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  action_text TEXT,
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  location_name TEXT,
  participants UUID[] DEFAULT '{}',
  post_id UUID,  -- FK added after posts table

  CONSTRAINT action_text_length CHECK (action_text IS NULL OR char_length(action_text) <= 100)
);

CREATE INDEX idx_lockout_sessions_user ON lockout_sessions (user_id);
CREATE INDEX idx_lockout_sessions_active ON lockout_sessions (user_id, ends_at) WHERE post_id IS NULL;

-- ----------------------------------------------------------------------------
-- 5. posts
-- ----------------------------------------------------------------------------
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  lockout_id UUID,
  thumbnail_url TEXT NOT NULL,
  thumbnail_width INT NOT NULL,
  thumbnail_height INT NOT NULL,
  content_type content_type NOT NULL,
  description TEXT,
  published_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  published_timezone TEXT DEFAULT 'UTC' NOT NULL,
  calendar_saved_at TIMESTAMPTZ,
  excluded_user_ids UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT description_length CHECK (description IS NULL OR char_length(description) <= 500)
);

-- Add FKs after both tables exist
ALTER TABLE posts ADD CONSTRAINT posts_lockout_id_fkey
  FOREIGN KEY (lockout_id) REFERENCES lockout_sessions(id);

ALTER TABLE lockout_sessions ADD CONSTRAINT lockout_sessions_post_id_fkey
  FOREIGN KEY (post_id) REFERENCES posts(id);

CREATE INDEX idx_posts_author ON posts (author_id);
CREATE INDEX idx_posts_lockout ON posts (lockout_id);
CREATE INDEX idx_posts_published ON posts (published_at DESC);
CREATE INDEX idx_posts_calendar ON posts (author_id, calendar_saved_at) WHERE calendar_saved_at IS NOT NULL;
CREATE INDEX idx_posts_pending ON posts (author_id, published_at) WHERE calendar_saved_at IS NULL;

-- ----------------------------------------------------------------------------
-- 6. post_media
-- ----------------------------------------------------------------------------
CREATE TABLE post_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL,
  width INT,
  height INT,
  duration_seconds FLOAT,
  sort_order INT DEFAULT 0 NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT valid_sort_order CHECK (sort_order >= 0)
);

CREATE INDEX idx_post_media_post ON post_media (post_id);
CREATE UNIQUE INDEX idx_post_media_unique_type ON post_media (post_id, media_type);

-- ----------------------------------------------------------------------------
-- 7. post_tags
-- ----------------------------------------------------------------------------
CREATE TABLE post_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  tagged_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT unique_post_tag UNIQUE (post_id, tagged_user_id)
);

CREATE INDEX idx_post_tags_post ON post_tags (post_id);
CREATE INDEX idx_post_tags_user ON post_tags (tagged_user_id);

-- ----------------------------------------------------------------------------
-- 8. post_comments
-- ----------------------------------------------------------------------------
CREATE TABLE post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ,

  CONSTRAINT content_length CHECK (char_length(content) <= 500)
);

CREATE INDEX idx_post_comments_post ON post_comments (post_id);
CREATE INDEX idx_post_comments_author ON post_comments (author_id);
CREATE INDEX idx_post_comments_created ON post_comments (post_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- 9. post_reactions
-- ----------------------------------------------------------------------------
CREATE TABLE post_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reaction TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_user_post_reaction UNIQUE (post_id, user_id)
);

CREATE INDEX idx_post_reactions_post ON post_reactions (post_id);
CREATE INDEX idx_post_reactions_user ON post_reactions (user_id);

-- ----------------------------------------------------------------------------
-- 10. notifications
-- ----------------------------------------------------------------------------
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  reference_id UUID NOT NULL,
  latest_actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  actor_count INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  read_at TIMESTAMPTZ,

  CONSTRAINT unique_notification UNIQUE (user_id, type, reference_id)
);

CREATE INDEX idx_notifications_user ON notifications (user_id);
CREATE INDEX idx_notifications_unread ON notifications (user_id, updated_at DESC) WHERE read_at IS NULL;

-- ----------------------------------------------------------------------------
-- 11. app_config
-- ----------------------------------------------------------------------------
CREATE TABLE app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- set_updated_at - Generic trigger function
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- upsert_notification - Insert or increment notification
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION upsert_notification(
  p_user_id UUID,
  p_type TEXT,
  p_reference_id UUID,
  p_actor_id UUID
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Don't notify user of their own actions
  IF p_user_id = p_actor_id THEN
    RETURN;
  END IF;

  INSERT INTO notifications (user_id, type, reference_id, latest_actor_id, actor_count)
  VALUES (p_user_id, p_type, p_reference_id, p_actor_id, 1)
  ON CONFLICT (user_id, type, reference_id) DO UPDATE SET
    latest_actor_id = p_actor_id,
    actor_count = notifications.actor_count + 1,
    updated_at = NOW(),
    read_at = NULL;
END;
$$;

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- get_user_feed - Friends' posts from last 24h
-- ----------------------------------------------------------------------------
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
  comment_count BIGINT
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
    COALESCE((SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id AND pc.deleted_at IS NULL), 0) AS comment_count
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  WHERE
    p.published_at > NOW() - INTERVAL '24 hours'
    AND NOT (v_user_id = ANY(p.excluded_user_ids))
    AND (
      p.author_id = v_user_id
      OR EXISTS (
        SELECT 1 FROM friendships f
        WHERE (f.user_a_id = v_user_id AND f.user_b_id = p.author_id)
           OR (f.user_b_id = v_user_id AND f.user_a_id = p.author_id)
      )
    )
    AND (p_cursor IS NULL OR p.published_at < p_cursor)
  ORDER BY p.published_at DESC
  LIMIT p_page_size;
END;
$$;

-- ----------------------------------------------------------------------------
-- get_user_calendar - View friend's or own saved calendar posts
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_calendar(
  p_target_user_id UUID,
  p_year INT,
  p_month INT
) RETURNS TABLE (
  id UUID,
  author_id UUID,
  author_username TEXT,
  author_avatar_url TEXT,
  thumbnail_url TEXT,
  thumbnail_width INT,
  thumbnail_height INT,
  content_type TEXT,
  description TEXT,
  published_at TIMESTAMPTZ,
  calendar_saved_at TIMESTAMPTZ,
  calendar_day INT
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

  -- Check friendship if not viewing own calendar
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
    p.id,
    p.author_id,
    prof.username AS author_username,
    prof.avatar_url AS author_avatar_url,
    p.thumbnail_url,
    p.thumbnail_width,
    p.thumbnail_height,
    p.content_type::TEXT,
    p.description,
    p.published_at,
    p.calendar_saved_at,
    EXTRACT(DAY FROM p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC'))::INT AS calendar_day
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  WHERE
    p.author_id = p_target_user_id
    AND p.calendar_saved_at IS NOT NULL
    AND EXTRACT(YEAR FROM p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = p_year
    AND EXTRACT(MONTH FROM p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = p_month
    AND (p_target_user_id = v_user_id OR NOT (v_user_id = ANY(p.excluded_user_ids)))
  ORDER BY p.published_at DESC;
END;
$$;

-- ----------------------------------------------------------------------------
-- save_post_to_calendar - Mark post as day's best (max 1 per day)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION save_post_to_calendar(p_post_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_post RECORD;
  v_calendar_date DATE;
  v_existing_post_id UUID;
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
    RETURN json_build_object('success', false, 'error', 'Cannot save other users posts');
  END IF;

  IF v_post.calendar_saved_at IS NOT NULL THEN
    RETURN json_build_object('success', true, 'message', 'Post already saved to calendar');
  END IF;

  -- Check 72h window
  IF v_post.published_at < NOW() - INTERVAL '72 hours' THEN
    RETURN json_build_object('success', false, 'error', 'Selection window has expired');
  END IF;

  -- Check if another post already saved for this calendar day
  v_calendar_date := DATE(v_post.published_at AT TIME ZONE COALESCE(v_post.published_timezone, 'UTC'));

  SELECT id INTO v_existing_post_id
  FROM posts
  WHERE author_id = v_user_id
    AND calendar_saved_at IS NOT NULL
    AND DATE(published_at AT TIME ZONE COALESCE(published_timezone, 'UTC')) = v_calendar_date
    AND id != p_post_id;

  IF v_existing_post_id IS NOT NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Another post already saved for this day',
      'existing_post_id', v_existing_post_id
    );
  END IF;

  UPDATE posts SET calendar_saved_at = NOW() WHERE id = p_post_id;

  RETURN json_build_object('success', true, 'message', 'Post saved to calendar');
END;
$$;

-- ----------------------------------------------------------------------------
-- get_friends_locked_out - Active lockouts of friends
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_friends_locked_out() RETURNS TABLE (
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
  participants UUID[]
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
    ls.participants
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

-- ----------------------------------------------------------------------------
-- join_friendship_transaction - Create friendship via invite code
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION join_friendship_transaction(
  p_invite_id UUID,
  p_user_id UUID,
  p_creator_id UUID
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_a UUID;
  v_user_b UUID;
  v_joiner_count INT;
  v_creator_count INT;
BEGIN
  -- Check if invite code is still valid
  IF NOT EXISTS (
    SELECT 1 FROM invite_codes
    WHERE id = p_invite_id
      AND used_by_id IS NULL
      AND expires_at > NOW()
  ) THEN
    RETURN json_build_object('success', false, 'error', 'Invite code is invalid, expired, or already used');
  END IF;

  -- Order UUIDs
  IF p_user_id < p_creator_id THEN
    v_user_a := p_user_id;
    v_user_b := p_creator_id;
  ELSE
    v_user_a := p_creator_id;
    v_user_b := p_user_id;
  END IF;

  -- Check if already friends
  IF EXISTS (
    SELECT 1 FROM friendships
    WHERE user_a_id = v_user_a AND user_b_id = v_user_b
  ) THEN
    RETURN json_build_object('success', false, 'error', 'Users are already friends');
  END IF;

  -- Check joiner's friend count (150 limit)
  SELECT COUNT(*) INTO v_joiner_count
  FROM friendships
  WHERE user_a_id = p_user_id OR user_b_id = p_user_id;

  IF v_joiner_count >= 150 THEN
    RETURN json_build_object('success', false, 'error', 'You have reached the maximum of 150 friends');
  END IF;

  -- Check creator's friend count (150 limit)
  SELECT COUNT(*) INTO v_creator_count
  FROM friendships
  WHERE user_a_id = p_creator_id OR user_b_id = p_creator_id;

  IF v_creator_count >= 150 THEN
    RETURN json_build_object('success', false, 'error', 'Creator has reached the maximum of 150 friends');
  END IF;

  -- Mark invite as used
  UPDATE invite_codes
  SET used_by_id = p_user_id, used_at = NOW()
  WHERE id = p_invite_id;

  -- Create friendship
  INSERT INTO friendships (user_a_id, user_b_id)
  VALUES (v_user_a, v_user_b);

  -- Notify creator
  PERFORM upsert_notification(p_creator_id, 'friend_joined', p_invite_id, p_user_id);

  RETURN json_build_object('success', true, 'message', 'Friendship created');
END;
$$;

-- ----------------------------------------------------------------------------
-- get_user_friends - List of friends with profile info
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_friends() RETURNS TABLE (
  friend_id UUID,
  username TEXT,
  biography TEXT,
  avatar_url TEXT,
  friendship_created_at TIMESTAMPTZ
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
    prof.id AS friend_id,
    prof.username,
    prof.biography,
    prof.avatar_url,
    f.created_at AS friendship_created_at
  FROM friendships f
  JOIN profiles prof ON (
    CASE
      WHEN f.user_a_id = v_user_id THEN f.user_b_id = prof.id
      ELSE f.user_a_id = prof.id
    END
  )
  WHERE f.user_a_id = v_user_id OR f.user_b_id = v_user_id
  ORDER BY prof.username;
END;
$$;

-- ----------------------------------------------------------------------------
-- join_lockout_session - Join a friend's active lockout
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION join_lockout_session(p_lockout_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_lockout RECORD;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  SELECT * INTO v_lockout FROM lockout_sessions WHERE id = p_lockout_id;

  IF v_lockout IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout not found');
  END IF;

  IF v_lockout.ends_at < NOW() OR v_lockout.post_id IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  -- Check friendship
  IF NOT EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = v_user_id AND f.user_b_id = v_lockout.user_id)
       OR (f.user_b_id = v_user_id AND f.user_a_id = v_lockout.user_id)
  ) THEN
    RETURN json_build_object('success', false, 'error', 'You must be friends to join a lockout');
  END IF;

  -- Check if already joined
  IF v_user_id = ANY(v_lockout.participants) THEN
    RETURN json_build_object('success', true, 'message', 'Already joined this lockout');
  END IF;

  -- Add to participants
  UPDATE lockout_sessions
  SET participants = array_append(participants, v_user_id)
  WHERE id = p_lockout_id;

  -- Notify owner
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  RETURN json_build_object('success', true, 'message', 'Joined lockout');
END;
$$;

-- ----------------------------------------------------------------------------
-- get_notification_feed - Aggregated notifications
-- ----------------------------------------------------------------------------
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
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  UPDATE profiles SET notifications_checked_at = NOW() WHERE id = v_user_id;

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
  ORDER BY n.updated_at DESC
  LIMIT 50;
END;
$$;

-- ----------------------------------------------------------------------------
-- mark_notifications_read
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_notifications_read() RETURNS VOID
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

  UPDATE notifications
  SET read_at = NOW()
  WHERE user_id = v_user_id AND read_at IS NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- get_unread_notification_count
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_unread_notification_count() RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_count INT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*)::INT INTO v_count
  FROM notifications
  WHERE user_id = v_user_id AND read_at IS NULL;

  RETURN v_count;
END;
$$;

-- ----------------------------------------------------------------------------
-- cleanup_unsaved_posts - Scheduled job to delete unsaved posts after 24h
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleanup_unsaved_posts() RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted_count INT;
  v_cutoff TIMESTAMPTZ;
BEGIN
  v_cutoff := NOW() - INTERVAL '24 hours';

  DELETE FROM posts
  WHERE calendar_saved_at IS NULL
    AND published_at < v_cutoff;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  RETURN json_build_object(
    'success', true,
    'deleted_count', v_deleted_count,
    'cutoff_time', v_cutoff,
    'executed_at', NOW()
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- get_post_by_id - Get single post with details
-- ----------------------------------------------------------------------------
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
  tagged_usernames TEXT[]
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
    COALESCE((SELECT array_agg(pt.username) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_usernames
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

-- ----------------------------------------------------------------------------
-- get_post_comments - Get comments for a post
-- ----------------------------------------------------------------------------
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
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Verify user can view this post
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
      )
  ) THEN
    RAISE EXCEPTION 'Post not found or access denied';
  END IF;

  RETURN QUERY
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
  ORDER BY pc.created_at ASC;
END;
$$;

-- ----------------------------------------------------------------------------
-- get_post_reactions - Get reactions for a post
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_post_reactions(p_post_id UUID) RETURNS TABLE (
  id UUID,
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  reaction TEXT,
  created_at TIMESTAMPTZ
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

  -- Verify user can view this post
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
      )
  ) THEN
    RAISE EXCEPTION 'Post not found or access denied';
  END IF;

  RETURN QUERY
  SELECT
    pr.id,
    pr.user_id,
    prof.username,
    prof.avatar_url,
    pr.reaction,
    pr.created_at
  FROM post_reactions pr
  JOIN profiles prof ON pr.user_id = prof.id
  WHERE pr.post_id = p_post_id
  ORDER BY pr.created_at DESC;
END;
$$;

-- ----------------------------------------------------------------------------
-- check_invite_codes_limit - Trigger function
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_invite_codes_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  active_count INT;
BEGIN
  SELECT COUNT(*) INTO active_count
  FROM invite_codes
  WHERE creator_id = NEW.creator_id
    AND used_by_id IS NULL
    AND expires_at > NOW();

  IF active_count >= 100 THEN
    RAISE EXCEPTION 'Maximum of 100 active invite codes reached';
  END IF;

  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- set_invite_used_at - Trigger function
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_invite_used_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.used_by_id IS NOT NULL AND OLD.used_by_id IS NULL THEN
    NEW.used_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Updated_at triggers
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_post_reactions_updated_at
  BEFORE UPDATE ON post_reactions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_app_config_updated_at
  BEFORE UPDATE ON app_config
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Invite code triggers
CREATE TRIGGER trg_check_invite_limit
  BEFORE INSERT ON invite_codes
  FOR EACH ROW EXECUTE FUNCTION check_invite_codes_limit();

CREATE TRIGGER trg_invite_codes_used_at
  BEFORE UPDATE ON invite_codes
  FOR EACH ROW EXECUTE FUNCTION set_invite_used_at();

-- ----------------------------------------------------------------------------
-- Notification triggers
-- ----------------------------------------------------------------------------

-- Reaction notification
CREATE OR REPLACE FUNCTION trigger_notification_on_reaction()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_post_author_id UUID;
BEGIN
  SELECT author_id INTO v_post_author_id FROM posts WHERE id = NEW.post_id;

  IF v_post_author_id IS NOT NULL THEN
    PERFORM upsert_notification(v_post_author_id, 'reaction', NEW.post_id, NEW.user_id);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notification_on_reaction
  AFTER INSERT ON post_reactions
  FOR EACH ROW EXECUTE FUNCTION trigger_notification_on_reaction();

-- Comment notification
CREATE OR REPLACE FUNCTION trigger_notification_on_comment()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_post_author_id UUID;
BEGIN
  SELECT author_id INTO v_post_author_id FROM posts WHERE id = NEW.post_id;

  IF v_post_author_id IS NOT NULL THEN
    PERFORM upsert_notification(v_post_author_id, 'comment', NEW.post_id, NEW.author_id);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notification_on_comment
  AFTER INSERT ON post_comments
  FOR EACH ROW EXECUTE FUNCTION trigger_notification_on_comment();

-- Tag notification
CREATE OR REPLACE FUNCTION trigger_notification_on_tag()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_post_author_id UUID;
BEGIN
  SELECT author_id INTO v_post_author_id FROM posts WHERE id = NEW.post_id;

  PERFORM upsert_notification(NEW.tagged_user_id, 'tag', NEW.post_id, v_post_author_id);

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notification_on_tag
  AFTER INSERT ON post_tags
  FOR EACH ROW EXECUTE FUNCTION trigger_notification_on_tag();

-- Lockout start notification (notify all friends)
CREATE OR REPLACE FUNCTION trigger_notification_on_lockout_start()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_friend_id UUID;
BEGIN
  FOR v_friend_id IN
    SELECT CASE
      WHEN f.user_a_id = NEW.user_id THEN f.user_b_id
      ELSE f.user_a_id
    END
    FROM friendships f
    WHERE f.user_a_id = NEW.user_id OR f.user_b_id = NEW.user_id
  LOOP
    PERFORM upsert_notification(v_friend_id, 'lockout_started', NEW.id, NEW.user_id);
  END LOOP;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notification_on_lockout_start
  AFTER INSERT ON lockout_sessions
  FOR EACH ROW EXECUTE FUNCTION trigger_notification_on_lockout_start();

-- Update weekly_lockout_minutes when lockout ends
CREATE OR REPLACE FUNCTION trigger_update_weekly_lockout_minutes()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_duration_minutes INT;
BEGIN
  IF OLD.post_id IS NULL AND NEW.post_id IS NOT NULL THEN
    v_duration_minutes := EXTRACT(EPOCH FROM (LEAST(NEW.ends_at, NOW()) - NEW.started_at)) / 60;

    UPDATE profiles
    SET weekly_lockout_minutes = weekly_lockout_minutes + v_duration_minutes
    WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_weekly_lockout_minutes
  AFTER UPDATE ON lockout_sessions
  FOR EACH ROW EXECUTE FUNCTION trigger_update_weekly_lockout_minutes();

-- Auto-populate denormalized fields in post_tags
CREATE OR REPLACE FUNCTION trigger_populate_post_tag_denorm()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  SELECT username, avatar_url
  INTO NEW.username, NEW.avatar_url
  FROM profiles
  WHERE id = NEW.tagged_user_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_populate_post_tag_denorm
  BEFORE INSERT ON post_tags
  FOR EACH ROW EXECUTE FUNCTION trigger_populate_post_tag_denorm();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- ----------------------------------------------------------------------------
-- profiles
-- ----------------------------------------------------------------------------
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile"
  ON profiles FOR DELETE
  USING (auth.uid() = id);

-- ----------------------------------------------------------------------------
-- friendships
-- ----------------------------------------------------------------------------
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their friendships"
  ON friendships FOR SELECT
  USING (auth.uid() IN (user_a_id, user_b_id));

CREATE POLICY "Users can delete their friendships"
  ON friendships FOR DELETE
  USING (auth.uid() IN (user_a_id, user_b_id));

-- INSERT via SECURITY DEFINER function only

-- ----------------------------------------------------------------------------
-- invite_codes
-- ----------------------------------------------------------------------------
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own invite codes"
  ON invite_codes FOR SELECT
  USING (auth.uid() = creator_id);

CREATE POLICY "Anyone can view valid codes for joining"
  ON invite_codes FOR SELECT
  USING (used_by_id IS NULL AND expires_at > NOW());

CREATE POLICY "Users can create invite codes"
  ON invite_codes FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update own invite codes"
  ON invite_codes FOR UPDATE
  USING (auth.uid() = creator_id);

-- ----------------------------------------------------------------------------
-- lockout_sessions
-- ----------------------------------------------------------------------------
ALTER TABLE lockout_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own lockouts"
  ON lockout_sessions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can view friends active lockouts"
  ON lockout_sessions FOR SELECT
  USING (
    post_id IS NULL
    AND ends_at > NOW()
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = auth.uid() AND f.user_b_id = lockout_sessions.user_id)
         OR (f.user_b_id = auth.uid() AND f.user_a_id = lockout_sessions.user_id)
    )
  );

CREATE POLICY "Users can create own lockouts"
  ON lockout_sessions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own lockouts"
  ON lockout_sessions FOR UPDATE
  USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- posts
-- ----------------------------------------------------------------------------
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own posts"
  ON posts FOR SELECT
  USING (author_id = auth.uid());

CREATE POLICY "Users can view friends posts not excluded"
  ON posts FOR SELECT
  USING (
    NOT (auth.uid() = ANY(excluded_user_ids))
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = auth.uid() AND f.user_b_id = posts.author_id)
         OR (f.user_b_id = auth.uid() AND f.user_a_id = posts.author_id)
    )
  );

CREATE POLICY "Users can create own posts"
  ON posts FOR INSERT
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  USING (author_id = auth.uid());

CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  USING (author_id = auth.uid());

-- ----------------------------------------------------------------------------
-- post_media
-- ----------------------------------------------------------------------------
ALTER TABLE post_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Media viewable via post access"
  ON post_media FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_media.post_id
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

CREATE POLICY "Users can manage own post media"
  ON post_media
  USING (
    EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_media.post_id AND p.author_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- post_tags
-- ----------------------------------------------------------------------------
ALTER TABLE post_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tags viewable via post access"
  ON post_tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_tags.post_id
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

CREATE POLICY "Authors can manage post tags"
  ON post_tags
  USING (
    EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_tags.post_id AND p.author_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- post_comments
-- ----------------------------------------------------------------------------
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments viewable via post access"
  ON post_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_comments.post_id
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

CREATE POLICY "Users can comment on visible posts"
  ON post_comments FOR INSERT
  WITH CHECK (
    author_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_comments.post_id
        AND NOT (auth.uid() = ANY(p.excluded_user_ids))
        AND (
          p.author_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM friendships f
            WHERE (f.user_a_id = auth.uid() AND f.user_b_id = p.author_id)
               OR (f.user_b_id = auth.uid() AND f.user_a_id = p.author_id)
          )
        )
    )
  );

CREATE POLICY "Users can soft delete own comments"
  ON post_comments FOR UPDATE
  USING (author_id = auth.uid());

-- ----------------------------------------------------------------------------
-- post_reactions
-- ----------------------------------------------------------------------------
ALTER TABLE post_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reactions are viewable by authenticated users"
  ON post_reactions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can react to visible posts"
  ON post_reactions FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM posts p
      WHERE p.id = post_reactions.post_id
        AND NOT (auth.uid() = ANY(p.excluded_user_ids))
        AND (
          p.author_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM friendships f
            WHERE (f.user_a_id = auth.uid() AND f.user_b_id = p.author_id)
               OR (f.user_b_id = auth.uid() AND f.user_a_id = p.author_id)
          )
        )
    )
  );

CREATE POLICY "Users can update own reactions"
  ON post_reactions FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own reactions"
  ON post_reactions FOR DELETE
  USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- notifications
-- ----------------------------------------------------------------------------
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (user_id = auth.uid());

-- INSERT via SECURITY DEFINER triggers only

-- ----------------------------------------------------------------------------
-- app_config
-- ----------------------------------------------------------------------------
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Config readable by security definer functions"
  ON app_config FOR SELECT
  USING (true);

-- ============================================================================
-- STORAGE BUCKETS (run in Supabase dashboard or via API)
-- ============================================================================
--
-- Create these storage buckets:
-- 1. avatars - public bucket for user avatars
-- 2. post_media - private bucket for post images/videos
--
-- Storage policies should allow:
-- - avatars: public read, authenticated write to own folder
-- - post_media: authenticated read/write based on post ownership
--
-- ============================================================================

-- ============================================================================
-- SCHEDULED JOBS
-- ============================================================================
--
-- Set up these cron jobs in Supabase:
--
-- 1. Cleanup unsaved posts (every hour)
--    SELECT cleanup_unsaved_posts();
--
-- 2. Reset weekly_lockout_minutes (every Monday at 00:00 UTC)
--    UPDATE profiles SET weekly_lockout_minutes = 0;
--
-- ============================================================================
