-- ============================================================================
-- MIGRATION 005: Lockout Calendar RPC
-- ============================================================================
-- Replaces get_user_calendar (saved posts) with get_user_lockout_calendar
-- Shows posts where lockout_id IS NOT NULL instead of calendar_saved_at IS NOT NULL
-- ============================================================================

-- ----------------------------------------------------------------------------
-- get_user_lockout_calendar - View user's lockout posts by month
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_lockout_calendar(
  p_target_user_id UUID,
  p_year INT,
  p_month INT
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
  ORDER BY p.published_at DESC;
END;
$$;

-- Add index to optimize lockout calendar queries
CREATE INDEX IF NOT EXISTS idx_posts_lockout_calendar
  ON posts (author_id, published_at)
  WHERE lockout_id IS NOT NULL;
