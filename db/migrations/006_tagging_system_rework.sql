-- ============================================================================
-- MIGRATION 006: Tagging System Rework
-- ============================================================================
-- Adds tag_type to distinguish participant tags from @mention tags
-- Creates comment_mentions table for tracking mentions in comments
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Add tag_type column to post_tags
-- Values: 'participant' (auto from lockout), 'mention' (manual @mention)
-- ----------------------------------------------------------------------------
ALTER TABLE post_tags ADD COLUMN IF NOT EXISTS tag_type TEXT DEFAULT 'mention';

-- Update existing tags from lockout posts to be 'participant' type
UPDATE post_tags
SET tag_type = 'participant'
WHERE post_id IN (
  SELECT p.id FROM posts p
  WHERE p.lockout_id IS NOT NULL
);

-- Create index for efficient filtering by tag_type
CREATE INDEX IF NOT EXISTS idx_post_tags_type ON post_tags (post_id, tag_type);

-- ----------------------------------------------------------------------------
-- Create comment_mentions table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS comment_mentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES post_comments(id) ON DELETE CASCADE,
  mentioned_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_comment_mention UNIQUE (comment_id, mentioned_user_id)
);

CREATE INDEX IF NOT EXISTS idx_comment_mentions_comment ON comment_mentions (comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_mentions_user ON comment_mentions (mentioned_user_id);

-- ----------------------------------------------------------------------------
-- RLS for comment_mentions
-- ----------------------------------------------------------------------------
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

-- Insert via trigger only (SECURITY DEFINER)

-- ----------------------------------------------------------------------------
-- Notification trigger for comment mentions
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_notification_on_comment_mention()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_comment_author_id UUID;
  v_post_id UUID;
BEGIN
  -- Get the comment author and post_id
  SELECT author_id, post_id INTO v_comment_author_id, v_post_id
  FROM post_comments
  WHERE id = NEW.comment_id;

  -- Send notification using post_id so mentions on same post aggregate
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

-- ----------------------------------------------------------------------------
-- Update get_post_by_id to include tag_type
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- RPC to add post tags with type
-- ----------------------------------------------------------------------------
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

  -- Verify user owns the post
  SELECT * INTO v_post FROM posts WHERE id = p_post_id;

  IF v_post IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Post not found');
  END IF;

  IF v_post.author_id != v_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Not authorized to tag on this post');
  END IF;

  -- Verify tagged user is a friend
  IF NOT EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = v_user_id AND f.user_b_id = p_tagged_user_id)
       OR (f.user_b_id = v_user_id AND f.user_a_id = p_tagged_user_id)
  ) THEN
    RETURN json_build_object('success', false, 'error', 'Can only tag friends');
  END IF;

  -- Insert tag (trigger will populate username/avatar_url)
  INSERT INTO post_tags (post_id, tagged_user_id, tag_type)
  VALUES (p_post_id, p_tagged_user_id, p_tag_type)
  ON CONFLICT (post_id, tagged_user_id) DO UPDATE SET tag_type = p_tag_type;

  RETURN json_build_object('success', true);
END;
$$;

-- ----------------------------------------------------------------------------
-- RPC to add comment mentions
-- ----------------------------------------------------------------------------
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

  -- Verify user owns the comment
  SELECT * INTO v_comment FROM post_comments WHERE id = p_comment_id;

  IF v_comment IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Comment not found');
  END IF;

  IF v_comment.author_id != v_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Not authorized');
  END IF;

  -- Get the post to verify friendship with mentioned users
  SELECT * INTO v_post FROM posts WHERE id = v_comment.post_id;

  -- Insert mentions for each valid friend
  FOREACH v_mentioned_id IN ARRAY p_mentioned_user_ids
  LOOP
    -- Only mention if user is a friend
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

-- ----------------------------------------------------------------------------
-- RPC to get user profile with connection status
-- For viewing profiles of non-friends (limited view)
-- ----------------------------------------------------------------------------
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
