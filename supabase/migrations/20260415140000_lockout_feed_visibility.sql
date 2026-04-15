-- ============================================================================
-- MIGRATION: Lockout-based feed visibility, per-viewer comment filtering,
--            participant data in post detail
-- ============================================================================
-- Depends on: lockout_participants table (20260415120000)
--
-- Changes:
--   1.  RLS policy: lockout participants can view lockout posts
--   2.  RLS policy: media viewable via lockout participation
--   3.  Replace get_user_feed() — lockout visibility, per-viewer comments,
--       per-participant score, completed_at duration, my_friends CTE
--   4.  Replace get_post_by_id() — lockout visibility, per-viewer comments,
--       participant arrays, my_friends CTE
--   5.  Replace get_post_comments() — lockout visibility, per-viewer filtering
-- ============================================================================


-- ============================================================================
-- 1. RLS: lockout participants can view lockout posts
-- ============================================================================
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

-- ============================================================================
-- 2. RLS: media viewable via lockout participation
-- ============================================================================
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


-- ============================================================================
-- 3. REPLACE get_user_feed()
-- ============================================================================
-- Key changes from previous version:
--   - my_friends CTE for comment filtering and is_author_connected
--   - Visibility WHERE adds lockout participation OR branch
--   - comment_count is per-viewer filtered (circle + author + self)
--   - lockout_score reads from lockout_participants per author
--   - lockout_duration_minutes uses COALESCE(completed_at, ends_at)
--   - is_author_connected uses CTE instead of inline EXISTS
-- ============================================================================
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
    -- Per-viewer filtered comment count: only comments from self, post author, or friends
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
    -- is_author_connected via CTE
    (p.author_id = v_user_id OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)) AS is_author_connected,
    -- Lockout score from lockout_participants per author
    (SELECT lp.goback_score::INT FROM lockout_participants lp WHERE lp.session_id = p.lockout_id AND lp.user_id = p.author_id LIMIT 1) AS lockout_score,
    -- Duration uses COALESCE(completed_at, ends_at)
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
      -- Friend or self visibility
      p.author_id = v_user_id
      OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)
      -- Lockout participation visibility
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


-- ============================================================================
-- 4. REPLACE get_post_by_id()
-- ============================================================================
-- Key changes from previous version:
--   - Lockout-based visibility in WHERE clause
--   - my_friends CTE for per-viewer comment filtering
--   - 4 new lockout participant columns
--   - lockout_score from lockout_participants
--   - lockout_duration_minutes uses COALESCE(completed_at, ends_at)
--   - is_author_connected via CTE
--
-- Must DROP first since return type changes (new columns).
-- ============================================================================
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
    -- Per-viewer filtered comment count
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
    -- is_author_connected via CTE
    (p.author_id = v_user_id OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)) AS is_author_connected,
    -- Lockout score from lockout_participants per author
    (SELECT lp.goback_score::INT FROM lockout_participants lp WHERE lp.session_id = p.lockout_id AND lp.user_id = p.author_id LIMIT 1) AS lockout_score,
    -- Duration uses COALESCE(completed_at, ends_at)
    CASE WHEN ls.id IS NOT NULL
      THEN EXTRACT(EPOCH FROM (COALESCE(ls.completed_at, ls.ends_at) - ls.started_at))::INT / 60
      ELSE NULL
    END AS lockout_duration_minutes,
    -- Tags
    COALESCE((SELECT array_agg(pt.tagged_user_id) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_user_ids,
    COALESCE((SELECT array_agg(pt.username) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tagged_usernames,
    COALESCE((SELECT array_agg(pt.tag_type) FROM post_tags pt WHERE pt.post_id = p.id), '{}') AS tag_types,
    -- Lockout participants (excluding the post author)
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
    AND NOT (v_user_id = ANY(p.excluded_user_ids))
    AND (
      -- Friend or self visibility
      p.author_id = v_user_id
      OR p.author_id IN (SELECT mf.friend_id FROM my_friends mf)
      -- Lockout participation visibility
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


-- ============================================================================
-- 5. REPLACE get_post_comments()
-- ============================================================================
-- Key changes from previous version:
--   - Visibility check adds lockout participation OR
--   - Comments filtered to self, post author, or friends via my_friends CTE
--   - Return type stays the same
-- ============================================================================
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

  -- Verify user can view this post (friend, self, or lockout participant)
  SELECT p.author_id INTO v_post_author_id
  FROM posts p
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
    );

  IF v_post_author_id IS NULL THEN
    RAISE EXCEPTION 'Post not found or access denied';
  END IF;

  RETURN QUERY
  WITH my_friends AS (
    SELECT
      CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id ELSE f.user_a_id END AS friend_id
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


-- ============================================================================
-- VERIFICATION NOTES
-- ============================================================================
--
-- After running this migration:
--
-- 1. RLS policies:
--    - Lockout participants can now see posts from lockouts they participated in,
--      even if the post author is not their friend
--    - Media attached to those posts is also visible
--
-- 2. get_user_feed():
--    - Feed now shows lockout posts from sessions the viewer participated in
--    - Comment counts only reflect comments from the viewer's circle
--    - lockout_score reads per-participant score from lockout_participants
--    - Duration uses completed_at when available
--    - is_author_connected uses CTE for consistency
--
-- 3. get_post_by_id():
--    - Same visibility changes as feed
--    - 4 new lockout participant columns for cross-circle display
--    - Participant arrays exclude the post author (shown separately)
--    - Return type changed (DROP + CREATE required)
--
-- 4. get_post_comments():
--    - Access check now includes lockout participation
--    - Comment list filtered to viewer's circle (self, post author, friends)
--    - Non-friend cross-circle participants' comments are hidden from each other
--    - Return type unchanged (CREATE OR REPLACE safe)
--
-- ============================================================================
