-- ============================================================================
-- Ensure all post-fetching functions filter deleted_at IS NULL.
-- Without this, soft-deleted posts reappear on refresh.
-- ============================================================================

-- 1. get_post_by_id: add deleted_at IS NULL
-- Must DROP+CREATE because return type was set by a previous migration.
DROP FUNCTION IF EXISTS get_post_by_id(UUID);

CREATE FUNCTION get_post_by_id(p_post_id UUID) RETURNS TABLE (
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
  lockout_duration_minutes INT,
  tagged_user_ids UUID[],
  tagged_usernames TEXT[],
  tag_types TEXT[],
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
    COALESCE((SELECT COUNT(*) FROM post_reactions pr WHERE pr.post_id = p.id), 0)::BIGINT AS reaction_count,
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
    END AS lockout_duration_minutes,
    COALESCE((SELECT array_agg(pt.tagged_user_id) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_user_ids,
    COALESCE((SELECT array_agg(pt.username) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_usernames,
    COALESCE((SELECT array_agg(pt.tag_type) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tag_types,
    COALESCE((
      SELECT array_agg(lp.user_id)
      FROM lockout_participants lp
      WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id
    ), '{}') AS lockout_participant_ids,
    COALESCE((
      SELECT array_agg(lp_prof.username)
      FROM lockout_participants lp
      JOIN profiles lp_prof ON lp.user_id = lp_prof.id
      WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id
    ), '{}') AS lockout_participant_usernames,
    COALESCE((
      SELECT array_agg(lp_prof.avatar_url)
      FROM lockout_participants lp
      JOIN profiles lp_prof ON lp.user_id = lp_prof.id
      WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id
    ), '{}') AS lockout_participant_avatars,
    COALESCE((
      SELECT array_agg(lp.joined_via)
      FROM lockout_participants lp
      WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id
    ), '{}') AS lockout_participant_joined_via
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  LEFT JOIN lockout_sessions ls ON p.lockout_id = ls.id
  WHERE
    p.id = p_post_id
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
    );
END;
$$;


-- 2. get_user_lockout_calendar: add deleted_at IS NULL
-- This function may have been created via dashboard. CREATE OR REPLACE
-- ensures it exists and filters deleted posts.
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
  video_url TEXT,
  published_at TIMESTAMPTZ,
  published_timezone TEXT,
  calendar_saved_at TIMESTAMPTZ,
  excluded_user_ids UUID[],
  tagged_usernames TEXT,
  tagged_user_ids TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  is_author_connected BOOLEAN,
  is_own_post BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_month_start DATE;
  v_month_end DATE;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  v_month_start := make_date(p_year, p_month, 1);
  v_month_end := (v_month_start + INTERVAL '1 month')::DATE;

  RETURN QUERY
  WITH my_friends AS (
    SELECT
      CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id ELSE f.user_a_id END AS friend_id
    FROM friendships f
    WHERE f.user_a_id = v_user_id OR f.user_b_id = v_user_id
  )
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
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
    p.published_at,
    p.published_timezone,
    p.calendar_saved_at,
    p.excluded_user_ids,
    (SELECT STRING_AGG(tprof.username, ', ' ORDER BY tprof.username)
     FROM post_tags pt JOIN profiles tprof ON pt.tagged_user_id = tprof.id
     WHERE pt.post_id = p.id) AS tagged_usernames,
    (SELECT STRING_AGG(pt.tagged_user_id::TEXT, ', ' ORDER BY pt.tagged_user_id::TEXT)
     FROM post_tags pt
     WHERE pt.post_id = p.id) AS tagged_user_ids,
    p.created_at,
    p.updated_at,
    (p.author_id = v_user_id OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)) AS is_author_connected,
    (p.author_id = p_target_user_id) AS is_own_post
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  WHERE
    p.author_id = p_target_user_id
    AND p.deleted_at IS NULL
    AND p.status = 'published'
    AND p.published_at >= v_month_start
    AND p.published_at < v_month_end
    AND NOT (v_user_id = ANY(p.excluded_user_ids))
  ORDER BY p.published_at DESC;
END;
$$;
