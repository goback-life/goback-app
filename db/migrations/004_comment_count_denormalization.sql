-- ============================================================================
-- COMMENT COUNT DENORMALIZATION MIGRATION
-- ============================================================================
-- Part of Phase 10: Comments Feature
-- - Denormalizes comment_count to eliminate N+1 queries
-- - Adds trigger to maintain count on INSERT/UPDATE (soft delete)
-- - Updates get_user_feed() and get_post_by_id() to use denormalized column
-- - Adds is_author_connected field (was missing)
-- - Adds comment limits: 250 chars max, 10 comments per user per post
-- ============================================================================

-- ============================================================================
-- 1. ADD DENORMALIZED COMMENT COUNT COLUMN
-- ============================================================================

ALTER TABLE posts ADD COLUMN IF NOT EXISTS comment_count INT DEFAULT 0;

-- ============================================================================
-- 2. BACKFILL EXISTING COMMENT COUNTS
-- ============================================================================

UPDATE posts p SET comment_count = (
  SELECT COUNT(*) FROM post_comments pc
  WHERE pc.post_id = p.id AND pc.deleted_at IS NULL
);

-- ============================================================================
-- 3. TRIGGER TO MAINTAIN COMMENT COUNT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_post_comment_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Decrement on soft delete (deleted_at transitions from NULL to non-NULL)
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = NEW.post_id;
    -- Increment on un-delete (deleted_at transitions from non-NULL to NULL)
    ELSIF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
      UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_post_comment_count ON post_comments;
CREATE TRIGGER trg_post_comment_count
AFTER INSERT OR UPDATE ON post_comments
FOR EACH ROW EXECUTE FUNCTION update_post_comment_count();

-- ============================================================================
-- 4. ADD COMMENT CONTENT LENGTH CONSTRAINT (250 chars max)
-- ============================================================================

ALTER TABLE post_comments
DROP CONSTRAINT IF EXISTS comment_content_length;

ALTER TABLE post_comments
ADD CONSTRAINT comment_content_length
CHECK (char_length(content) <= 250);

-- ============================================================================
-- 5. TRIGGER TO ENFORCE 10 COMMENTS PER USER PER POST
-- ============================================================================

CREATE OR REPLACE FUNCTION enforce_comment_limit_per_user()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_comment_count INT;
BEGIN
  -- Count existing non-deleted comments by this user on this post
  SELECT COUNT(*) INTO v_comment_count
  FROM post_comments
  WHERE post_id = NEW.post_id
    AND author_id = NEW.author_id
    AND deleted_at IS NULL;

  -- Limit is 10 comments per user per post
  IF v_comment_count >= 10 THEN
    RAISE EXCEPTION 'Comment limit reached: maximum 10 comments per user per post';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_comment_limit ON post_comments;
CREATE TRIGGER trg_enforce_comment_limit
BEFORE INSERT ON post_comments
FOR EACH ROW EXECUTE FUNCTION enforce_comment_limit_per_user();

-- ============================================================================
-- 6. UPDATE get_user_feed() TO USE DENORMALIZED COLUMN + is_author_connected
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
  is_author_connected BOOLEAN
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
    )) AS is_author_connected
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

-- ============================================================================
-- 7. UPDATE get_post_by_id() TO USE DENORMALIZED COLUMN + is_author_connected
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
  is_author_connected BOOLEAN
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
    )) AS is_author_connected
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

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
