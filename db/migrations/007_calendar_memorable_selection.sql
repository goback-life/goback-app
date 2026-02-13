-- ============================================================================
-- MIGRATION 007: Calendar "Most Memorable" Selection Flow
-- ============================================================================
-- Updates calendar RPC to filter by calendar_saved_at IS NOT NULL
-- Adds RPC for getting pending selection posts
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Get pending posts for selection (user's posts from yesterday that are unsaved)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_pending_selection_posts(
  p_date DATE DEFAULT NULL  -- defaults to yesterday
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

  -- If date given, use it; otherwise find most recent date within 72h with unsaved lockout posts
  IF p_date IS NOT NULL THEN
    v_target_date := p_date;
  ELSE
    SELECT DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC'))
    INTO v_target_date
    FROM posts p
    WHERE
      p.author_id = v_user_id
      AND p.calendar_saved_at IS NULL
      AND p.lockout_id IS NOT NULL
      AND p.published_at > NOW() - INTERVAL '72 hours'
    ORDER BY p.published_at DESC
    LIMIT 1;

    IF v_target_date IS NULL THEN
      RETURN;
    END IF;
  END IF;

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
    AND p.published_at > NOW() - INTERVAL '72 hours'
  ORDER BY p.published_at DESC;
END;
$$;

-- ----------------------------------------------------------------------------
-- Unsave post from calendar
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Update get_user_lockout_calendar to optionally filter by saved posts only
-- When p_saved_only is true, only returns posts with calendar_saved_at IS NOT NULL
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Check if user has pending selection for a specific date
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION has_pending_selection(
  p_date DATE DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_count INT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  IF p_date IS NOT NULL THEN
    SELECT COUNT(*) INTO v_count
    FROM posts p
    WHERE
      p.author_id = v_user_id
      AND p.calendar_saved_at IS NULL
      AND p.lockout_id IS NOT NULL
      AND DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = p_date
      AND p.published_at > NOW() - INTERVAL '72 hours';
  ELSE
    SELECT COUNT(*) INTO v_count
    FROM posts p
    WHERE
      p.author_id = v_user_id
      AND p.calendar_saved_at IS NULL
      AND p.lockout_id IS NOT NULL
      AND p.published_at > NOW() - INTERVAL '72 hours';
  END IF;

  RETURN v_count > 0;
END;
$$;
