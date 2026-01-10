-- Migration: Create notifications system
-- This migration creates the notifications table, RPC function for aggregated notifications,
-- and triggers to automatically create notifications from reactions, tags, replies, and circle joins.

-- Create notifications table
CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    notification_type text NOT NULL CHECK (notification_type IN ('reaction', 'tag', 'reply', 'circle_join')),
    related_post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    related_user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    read_at timestamp with time zone,
    CONSTRAINT notifications_user_id_check CHECK (user_id != related_user_id)
);

-- Create indexes for efficient querying
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, read_at) WHERE read_at IS NULL;
CREATE INDEX idx_notifications_related_post ON notifications(notification_type, related_post_id) WHERE related_post_id IS NOT NULL;

-- Add comment to document the table
COMMENT ON TABLE public.notifications IS 'Stores notifications for users when their posts are reacted to, they are tagged, their posts receive replies, or someone joins their circle.';

-- Create RPC function for aggregated notifications (following get_user_feed pattern)
CREATE OR REPLACE FUNCTION public.get_aggregated_notifications(
    p_user_id uuid,
    page_size integer DEFAULT 20,
    page_offset integer DEFAULT 0
) RETURNS TABLE(
    notification_type text,
    related_post_id uuid,
    actor_ids jsonb,
    actor_usernames jsonb,
    actor_avatar_urls jsonb,
    count integer,
    latest_created_at timestamp with time zone,
    is_read boolean,
    post_thumbnail_url text,
    post_content_type text
) LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    RETURN QUERY
    WITH actor_times AS (
        SELECT 
            n.notification_type,
            n.related_post_id,
            n.related_user_id,
            MIN(n.created_at) as first_created_at,
            MAX(n.created_at) as latest_created_at,
            BOOL_OR(n.read_at IS NULL) as has_unread
        FROM notifications n
        WHERE n.user_id = p_user_id
        GROUP BY n.notification_type, n.related_post_id, n.related_user_id
    ),
    ordered_actors AS (
        SELECT 
            at.notification_type,
            at.related_post_id,
            at.related_user_id,
            at.first_created_at,
            at.latest_created_at,
            at.has_unread,
            p.username
        FROM actor_times at
        LEFT JOIN profiles p ON at.related_user_id = p.id
        ORDER BY at.notification_type, at.related_post_id, at.first_created_at DESC
    ),
    aggregated AS (
        SELECT 
            oa.notification_type,
            oa.related_post_id,
            jsonb_agg(oa.related_user_id ORDER BY oa.first_created_at DESC) as actor_ids,
            jsonb_agg(oa.username ORDER BY oa.first_created_at DESC) FILTER (WHERE oa.username IS NOT NULL) as actor_usernames,
            COUNT(*)::integer as count,
            MAX(oa.latest_created_at) as latest_created_at,
            BOOL_OR(oa.has_unread) as has_unread
        FROM ordered_actors oa
        GROUP BY oa.notification_type, oa.related_post_id
        ORDER BY MAX(oa.latest_created_at) DESC
        LIMIT page_size OFFSET page_offset
    )
    SELECT 
        a.notification_type,
        a.related_post_id,
        a.actor_ids,
        a.actor_usernames,
        -- Return NULL for avatar_urls (following existing pattern - enriched separately)
        NULL::jsonb as actor_avatar_urls,
        a.count,
        a.latest_created_at,
        NOT a.has_unread as is_read,
        p.thumbnail_url as post_thumbnail_url,
        p.content_type::text as post_content_type
    FROM aggregated a
    LEFT JOIN posts p ON a.related_post_id = p.id;
END;
$$;

-- Add comment to document the function
COMMENT ON FUNCTION public.get_aggregated_notifications(uuid, integer, integer) IS 'Returns aggregated notifications for a user, grouping by type and post. Follows get_user_feed pattern.';

-- Create function for reaction notification trigger
CREATE OR REPLACE FUNCTION create_reaction_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_post_id, related_user_id)
    SELECT p.author_id, 'reaction', NEW.post_id, NEW.user_id
    FROM posts p
    WHERE p.id = NEW.post_id AND p.author_id != NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function for tag notification trigger
CREATE OR REPLACE FUNCTION create_tag_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_post_id, related_user_id)
    SELECT NEW.tagged_user_id, 'tag', NEW.post_id, p.author_id
    FROM posts p
    WHERE p.id = NEW.post_id AND p.author_id != NEW.tagged_user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function for reply notification trigger
CREATE OR REPLACE FUNCTION create_reply_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_post_id, related_user_id)
    SELECT p.author_id, 'reply', NEW.parent_id, NEW.author_id
    FROM posts p
    WHERE p.id = NEW.parent_id 
      AND p.author_id != NEW.author_id
      AND NEW.status = 'published';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function for circle join notification trigger
CREATE OR REPLACE FUNCTION create_circle_join_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_user_id)
    VALUES (NEW.connection_id, 'circle_join', NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER on_reaction_created
AFTER INSERT ON post_reactions
FOR EACH ROW EXECUTE FUNCTION create_reaction_notification();

CREATE TRIGGER on_tag_created
AFTER INSERT ON post_tags
FOR EACH ROW EXECUTE FUNCTION create_tag_notification();

CREATE TRIGGER on_reply_created
AFTER INSERT ON posts
FOR EACH ROW
WHEN (NEW.parent_id IS NOT NULL)
EXECUTE FUNCTION create_reply_notification();

CREATE TRIGGER on_connection_created
AFTER INSERT ON connections
FOR EACH ROW EXECUTE FUNCTION create_circle_join_notification();

