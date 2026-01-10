-- Migration: Fix reply notification trigger
-- This migration adds an UPDATE trigger to handle reply notifications when posts
-- are published after being created as drafts (two-step process: create draft, then publish).
-- 
-- Issue: The original trigger only fires on INSERT when status='published', but posts
-- are created as drafts and then published via UPDATE. This migration adds an UPDATE
-- trigger to catch the status change to 'published'.

-- Create function for reply notification trigger (UPDATE)
-- This handles the case where a post's status changes to 'published' after being created as draft
CREATE OR REPLACE FUNCTION create_reply_notification_on_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create notification if status changed to 'published' and parent_id exists
    IF NEW.status = 'published' 
       AND NEW.parent_id IS NOT NULL
       AND (OLD.status IS NULL OR OLD.status != 'published') THEN
        INSERT INTO notifications (user_id, notification_type, related_post_id, related_user_id)
        SELECT p.author_id, 'reply', NEW.parent_id, NEW.author_id
        FROM posts p
        WHERE p.id = NEW.parent_id 
          AND p.author_id != NEW.author_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add comment to document the function
COMMENT ON FUNCTION public.create_reply_notification_on_update() IS 'Creates reply notifications when a post status changes to published and the post has a parent_id (is a reply).';

-- Create UPDATE trigger for reply notifications
-- This trigger fires when a post is updated and becomes published
CREATE TRIGGER on_reply_published
AFTER UPDATE ON posts
FOR EACH ROW
WHEN (NEW.parent_id IS NOT NULL)
EXECUTE FUNCTION create_reply_notification_on_update();

