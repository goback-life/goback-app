-- Fix: add deleted_at IS NULL filter to get_user_feed.
-- The lockout_feed_visibility migration omitted this filter, causing
-- soft-deleted posts to reappear on feed refresh.
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
    SELECT
      CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id ELSE f.user_a_id END AS friend_id
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
    COALESCE((
      SELECT COUNT(*)
      FROM post_comments pc
      WHERE pc.post_id = p.id
        AND pc.deleted_at IS NULL
        AND (
          pc.author_id = v_user_id
          OR pc.author_id = p.author_id
          OR pc.author_id IN (SELECT mf.friend_id FROM my_friends mf)
        )
    ), 0)::BIGINT AS comment_count,
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
    (p.author_id = v_user_id OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)) AS is_author_connected,
    (SELECT lp.goback_score::INT FROM lockout_participants lp WHERE lp.session_id = p.lockout_id AND lp.user_id = p.author_id LIMIT 1) AS lockout_score,
    CASE WHEN ls.id IS NOT NULL
      THEN EXTRACT(EPOCH FROM (COALESCE(ls.completed_at, ls.ends_at) - ls.started_at))::INT / 60
      ELSE NULL
    END AS lockout_duration_minutes
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  LEFT JOIN lockout_sessions ls ON p.lockout_id = ls.id
  WHERE
    p.published_at > NOW() - INTERVAL '24 hours'
    AND p.deleted_at IS NULL
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
