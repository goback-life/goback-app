-- ============================================================================
-- GOBACK SCORE MIGRATION
-- ============================================================================
-- Adds goback_score column to lockout_sessions and exposes it through
-- the feed RPCs so the client can display score + duration on lockout posts.
--
-- Changes:
-- 1. Add goback_score column to lockout_sessions
-- 2. Create update_lockout_score() RPC
-- 3. Update get_user_feed() to LEFT JOIN lockout_sessions for score/duration
-- 4. Update get_post_by_id() same
-- ============================================================================

-- ============================================================================
-- 1. ADD GOBACK SCORE COLUMN
-- ============================================================================

ALTER TABLE lockout_sessions
ADD COLUMN IF NOT EXISTS goback_score SMALLINT DEFAULT NULL;

-- ============================================================================
-- 2. CREATE update_lockout_score RPC
-- ============================================================================
-- Called by the client after lockout completes to persist the calculated score.
-- Only the session owner or a participant may update.
-- ============================================================================

CREATE OR REPLACE FUNCTION update_lockout_score(
  p_session_id UUID,
  p_score INT
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF v_session IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  -- Verify user is owner or participant
  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  -- Clamp score to 0-100
  UPDATE lockout_sessions
  SET goback_score = LEAST(100, GREATEST(0, p_score))
  WHERE id = p_session_id;

  RETURN json_build_object('success', true);
END;
$$;

-- ============================================================================
-- 3. UPDATE get_user_feed() - Add lockout_score + lockout_duration_minutes
-- ============================================================================

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
    p.comment_count::BIGINT,
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
    -- is_author_connected: true if current user is connected to post author
    (p.author_id = v_user_id OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = p.author_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = p.author_id)
    )) AS is_author_connected,
    -- Lockout score and duration (NULL for non-lockout posts)
    ls.goback_score::INT AS lockout_score,
    CASE WHEN ls.id IS NOT NULL
      THEN EXTRACT(EPOCH FROM (ls.ends_at - ls.started_at))::INT / 60
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

-- ============================================================================
-- 4. UPDATE get_post_by_id() - Add lockout_score + lockout_duration_minutes
-- ============================================================================

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
  video_url TEXT,
  tagged_user_ids UUID[],
  tagged_usernames TEXT[],
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
    p.comment_count::BIGINT,
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
    COALESCE((SELECT array_agg(pt.tagged_user_id) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_user_ids,
    COALESCE((SELECT array_agg(pt.username) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_usernames,
    -- is_author_connected: true if current user is connected to post author
    (p.author_id = v_user_id OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = p.author_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = p.author_id)
    )) AS is_author_connected,
    -- Lockout score and duration (NULL for non-lockout posts)
    ls.goback_score::INT AS lockout_score,
    CASE WHEN ls.id IS NOT NULL
      THEN EXTRACT(EPOCH FROM (ls.ends_at - ls.started_at))::INT / 60
      ELSE NULL
    END AS lockout_duration_minutes
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  LEFT JOIN lockout_sessions ls ON p.lockout_id = ls.id
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

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
