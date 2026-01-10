-- Migration: Add is_lockout_post flag to posts table
-- This flag identifies posts created through the official lockout flow
-- and prevents users from creating fake lockout posts

ALTER TABLE public.posts
ADD COLUMN is_lockout_post boolean NOT NULL DEFAULT false;

-- Add comment to document the field
COMMENT ON COLUMN public.posts.is_lockout_post IS 'Indicates if this post was created through the official manual lockout flow. Used to validate join lockout feature.';

-- IMPORTANT: After running this migration, update the following database functions
-- to include is_lockout_post in their SELECT statements:
-- - get_user_feed
-- - get_post_by_id
-- - get_post_replies
-- These functions need to return is_lockout_post so the app can properly validate lockout posts.

