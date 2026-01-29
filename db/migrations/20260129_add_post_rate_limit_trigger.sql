-- Migration: Add post rate limit trigger
-- Description: Prevents users from publishing more than 50 posts per hour
-- Date: 2026-01-29

-- Function to check post rate limit before publish
CREATE OR REPLACE FUNCTION "public"."check_post_rate_limit"()
RETURNS "trigger"
LANGUAGE "plpgsql"
AS $$
DECLARE
  recent_posts_count integer;
BEGIN
  -- Only check on publish (when published_at is being set for the first time)
  IF NEW.published_at IS NOT NULL AND OLD.published_at IS NULL THEN
    SELECT COUNT(*) INTO recent_posts_count
    FROM public.posts
    WHERE author_id = NEW.author_id
      AND published_at IS NOT NULL
      AND published_at > now() - INTERVAL '1 hour'
      AND deleted_at IS NULL;

    IF recent_posts_count >= 50 THEN
      RAISE EXCEPTION 'Rate limit exceeded: maximum 50 posts per hour';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger on posts table for UPDATE operations (publish sets published_at)
DROP TRIGGER IF EXISTS "trg_check_post_rate_limit" ON "public"."posts";

CREATE TRIGGER "trg_check_post_rate_limit"
BEFORE UPDATE ON "public"."posts"
FOR EACH ROW
WHEN (NEW.published_at IS NOT NULL AND OLD.published_at IS NULL)
EXECUTE FUNCTION "public"."check_post_rate_limit"();

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION "public"."check_post_rate_limit"() TO authenticated;

COMMENT ON FUNCTION "public"."check_post_rate_limit"() IS
'Rate limit check: prevents users from publishing more than 50 posts per hour.
Only counts published posts (published_at IS NOT NULL) that are not deleted.
Triggers on UPDATE when published_at changes from NULL to a value.';
