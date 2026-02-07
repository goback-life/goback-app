-- ============================================================================
-- FEED OPTIMIZATION MIGRATION
-- ============================================================================
-- Part of Phase 4: Feed Posts Simplification
-- - Denormalizes reaction_count to eliminate N+1 queries
-- - Enforces lockout_id on new posts (server-side security)
-- - Adds atomic hidePost RPC to prevent race conditions
-- - Adds video duration constraint
-- ============================================================================

-- ============================================================================
-- 1. DENORMALIZE REACTION COUNT
-- ============================================================================

-- Add denormalized reaction count column (comments not implemented yet)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS reaction_count INT DEFAULT 0;

-- Backfill existing reaction counts
UPDATE posts p SET reaction_count = (
  SELECT COUNT(*) FROM post_reactions pr WHERE pr.post_id = p.id
);

-- Trigger to maintain reaction count
CREATE OR REPLACE FUNCTION update_post_reaction_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET reaction_count = reaction_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET reaction_count = GREATEST(reaction_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_post_reaction_count ON post_reactions;
CREATE TRIGGER trg_post_reaction_count
AFTER INSERT OR DELETE ON post_reactions
FOR EACH ROW EXECUTE FUNCTION update_post_reaction_count();

-- ============================================================================
-- 2. UPDATE get_user_feed TO USE DENORMALIZED COLUMN + VIDEO_URL
-- ============================================================================

-- Drop existing function first (signature changed)
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
  video_url TEXT  -- Added for video posts
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
    p.reaction_count::BIGINT,  -- Denormalized column (no subquery)
    COALESCE((SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id AND pc.deleted_at IS NULL), 0) AS comment_count,
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url
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
-- 3. UPDATE get_post_by_id TO USE DENORMALIZED COLUMN + VIDEO_URL
-- ============================================================================

-- Drop existing function first (signature changed)
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
  video_url TEXT,  -- Added for video posts
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
    p.reaction_count::BIGINT,  -- Denormalized column (no subquery)
    COALESCE((SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id AND pc.deleted_at IS NULL), 0) AS comment_count,
    (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
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

-- ============================================================================
-- 4. ENFORCE LOCKOUT_ID ON NEW POSTS (SECURITY)
-- ============================================================================

-- Trigger to enforce lockout_id is NOT NULL for new posts
-- Allows NULL for existing posts and for UPDATEs (edits)
CREATE OR REPLACE FUNCTION enforce_lockout_on_post()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Only enforce on INSERT (new posts), not UPDATE (edits)
  IF TG_OP = 'INSERT' AND NEW.lockout_id IS NULL THEN
    RAISE EXCEPTION 'Posts must be linked to a lockout session';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_lockout_on_post ON posts;
CREATE TRIGGER trg_enforce_lockout_on_post
BEFORE INSERT ON posts
FOR EACH ROW EXECUTE FUNCTION enforce_lockout_on_post();

-- ============================================================================
-- 5. ATOMIC hidePost OPERATION (RACE CONDITION FIX)
-- ============================================================================

CREATE OR REPLACE FUNCTION hide_post_for_user(p_post_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_updated BOOLEAN;
  v_row_count INT;
BEGIN
  UPDATE posts
  SET excluded_user_ids = array_append(COALESCE(excluded_user_ids, '{}'), p_user_id)
  WHERE id = p_post_id
    AND NOT (p_user_id = ANY(COALESCE(excluded_user_ids, '{}')));

  GET DIAGNOSTICS v_row_count = ROW_COUNT;
  v_updated := v_row_count > 0;
  RETURN v_updated;
END;
$$;

-- ============================================================================
-- 6. VIDEO DURATION CONSTRAINT (SERVER-SIDE BACKUP)
-- ============================================================================

-- The post_media table already has duration_seconds column
-- Add constraint to limit videos to 60 seconds max
ALTER TABLE post_media
DROP CONSTRAINT IF EXISTS video_duration_limit;

ALTER TABLE post_media
ADD CONSTRAINT video_duration_limit
CHECK (duration_seconds IS NULL OR duration_seconds <= 60);

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
