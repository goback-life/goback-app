-- ================================================================================
-- Migration: Sync Staging to Production
-- Date: 2026-01-26
-- Description: Complete migration to sync all schema changes from staging to production
-- 
-- IMPORTANT: Run this in your production Supabase SQL Editor
-- WARNING: This migration should be run as a single transaction where possible.
--          Some statements (like ALTER TYPE ADD VALUE) cannot run in a transaction.
--          Follow the sections in order.
-- ================================================================================


-- ================================================================================
-- SECTION 1: ENUM CHANGES (Run this FIRST, separately if needed)
-- Note: ALTER TYPE ADD VALUE cannot run inside a transaction in PostgreSQL < 14
-- ================================================================================

-- Add 'text' to content_type enum
ALTER TYPE public.content_type ADD VALUE IF NOT EXISTS 'text';


-- ================================================================================
-- SECTION 2: TABLE CHANGES
-- ================================================================================

-- 2.1 Add is_lockout_post column to posts table
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS is_lockout_post boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.posts.is_lockout_post IS 'Indicates if this post was created through the official manual lockout flow. Used to validate join lockout feature.';


-- 2.2 Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL,
    notification_type text NOT NULL,
    related_post_id uuid,
    related_user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    read_at timestamp with time zone,
    CONSTRAINT notifications_notification_type_check CHECK (notification_type = ANY (ARRAY['reaction'::text, 'tag'::text, 'reply'::text, 'circle_join'::text])),
    CONSTRAINT notifications_user_id_check CHECK (user_id <> related_user_id)
);

COMMENT ON TABLE public.notifications IS 'Stores notifications for users when their posts are reacted to, they are tagged, their posts receive replies, or someone joins their circle.';


-- ================================================================================
-- SECTION 3: INDEXES FOR NOTIFICATIONS TABLE
-- ================================================================================

CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON public.notifications USING btree (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications USING btree (user_id, read_at) WHERE (read_at IS NULL);
CREATE INDEX IF NOT EXISTS idx_notifications_related_post ON public.notifications USING btree (notification_type, related_post_id) WHERE (related_post_id IS NOT NULL);


-- ================================================================================
-- SECTION 4: FOREIGN KEYS FOR NOTIFICATIONS TABLE
-- ================================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'notifications_user_id_fkey' AND table_name = 'notifications') THEN
        ALTER TABLE public.notifications
        ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'notifications_related_post_id_fkey' AND table_name = 'notifications') THEN
        ALTER TABLE public.notifications
        ADD CONSTRAINT notifications_related_post_id_fkey FOREIGN KEY (related_post_id) REFERENCES public.posts(id) ON DELETE CASCADE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'notifications_related_user_id_fkey' AND table_name = 'notifications') THEN
        ALTER TABLE public.notifications
        ADD CONSTRAINT notifications_related_user_id_fkey FOREIGN KEY (related_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
END $$;


-- ================================================================================
-- SECTION 5: ENABLE RLS FOR NOTIFICATIONS TABLE
-- ================================================================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;


-- ================================================================================
-- SECTION 6: POLICIES FOR NOTIFICATIONS TABLE
-- ================================================================================

-- Drop policies if they exist (to make migration idempotent)
DROP POLICY IF EXISTS "Users can read their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Trigger functions can insert notifications" ON public.notifications;

-- Create policies
CREATE POLICY "Users can read their own notifications" ON public.notifications 
FOR SELECT TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON public.notifications 
FOR UPDATE TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Trigger functions can insert notifications" ON public.notifications 
FOR INSERT TO authenticated 
WITH CHECK (true);


-- ================================================================================
-- SECTION 7: NEW FUNCTIONS
-- ================================================================================

-- 7.1 check_phone_numbers_exist
CREATE OR REPLACE FUNCTION public.check_phone_numbers_exist(phone_numbers text[]) 
RETURNS text[]
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    RETURN ARRAY(
        SELECT DISTINCT au.phone
        FROM auth.users au
        WHERE au.phone = ANY(phone_numbers)
        AND au.phone IS NOT NULL
    );
END;$$;


-- 7.2 cleanup_old_read_notifications
CREATE OR REPLACE FUNCTION public.cleanup_old_read_notifications() 
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.notifications
  WHERE read_at IS NOT NULL
    AND read_at < NOW() - INTERVAL '25 hours';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION public.cleanup_old_read_notifications() IS 'Deletes notifications that have been read 25+ hours ago. Returns the number of deleted notifications.';


-- 7.3 create_reaction_notification (trigger function)
CREATE OR REPLACE FUNCTION public.create_reaction_notification()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_post_id, related_user_id)
    SELECT p.author_id, 'reaction', NEW.post_id, NEW.user_id
    FROM posts p
    WHERE p.id = NEW.post_id AND p.author_id != NEW.user_id;
    RETURN NEW;
END;
$$;


-- 7.4 create_tag_notification (trigger function)
CREATE OR REPLACE FUNCTION public.create_tag_notification()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_post_id, related_user_id)
    SELECT NEW.tagged_user_id, 'tag', NEW.post_id, p.author_id
    FROM posts p
    WHERE p.id = NEW.post_id AND p.author_id != NEW.tagged_user_id;
    RETURN NEW;
END;
$$;


-- 7.5 create_reply_notification (trigger function for INSERT)
CREATE OR REPLACE FUNCTION public.create_reply_notification()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_post_id, related_user_id)
    SELECT p.author_id, 'reply', NEW.parent_id, NEW.author_id
    FROM posts p
    WHERE p.id = NEW.parent_id 
      AND p.author_id != NEW.author_id
      AND NEW.status = 'published';
    RETURN NEW;
END;
$$;


-- 7.6 create_reply_notification_on_update (trigger function for UPDATE)
CREATE OR REPLACE FUNCTION public.create_reply_notification_on_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
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
$$;

COMMENT ON FUNCTION public.create_reply_notification_on_update() IS 'Creates reply notifications when a post status changes to published and the post has a parent_id (is a reply).';


-- 7.7 create_circle_join_notification (trigger function)
CREATE OR REPLACE FUNCTION public.create_circle_join_notification()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO notifications (user_id, notification_type, related_user_id)
    VALUES (NEW.connection_id, 'circle_join', NEW.user_id);
    RETURN NEW;
END;
$$;


-- 7.8 get_aggregated_notifications (RPC function)
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

COMMENT ON FUNCTION public.get_aggregated_notifications(uuid, integer, integer) IS 'Returns aggregated notifications for a user, grouping by type and post. Follows get_user_feed pattern.';


-- ================================================================================
-- SECTION 8: MODIFIED FUNCTIONS
-- ================================================================================

-- IMPORTANT: Drop functions with changed return types first
-- These functions have new return columns (is_lockout_post) which changes their signature

DROP FUNCTION IF EXISTS public.get_user_feed(uuid, date, integer, integer, timestamp with time zone, timestamp with time zone);
DROP FUNCTION IF EXISTS public.get_user_feed(uuid, timestamp with time zone, integer, integer, timestamp with time zone, timestamp with time zone);
DROP FUNCTION IF EXISTS public.get_post_by_id(uuid, uuid);

-- 8.1 Update join_circle_transaction with circle size limit checks (150)
CREATE OR REPLACE FUNCTION public.join_circle_transaction(invite_id uuid, user_id uuid, creator_id uuid) 
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Check if invite code is still valid and not used
    IF NOT EXISTS (
        SELECT 1 FROM invite_codes 
        WHERE id = invite_id 
        AND used_by_id IS NULL 
        AND expires_at > NOW()
    ) THEN
        RAISE EXCEPTION 'Invite code is invalid, expired, or already used';
    END IF;
    
    -- Check if users are not already connected
    IF EXISTS (
        SELECT 1 FROM connections 
        WHERE (connections.user_id = join_circle_transaction.user_id AND connections.connection_id = join_circle_transaction.creator_id)
        OR (connections.user_id = join_circle_transaction.creator_id AND connections.connection_id = join_circle_transaction.user_id)
    ) THEN
        RAISE EXCEPTION 'Users are already connected';
    END IF;
    
    -- Check if joiner has reached circle size limit (150)
    IF (
        SELECT COUNT(*) FROM connections 
        WHERE connections.user_id = join_circle_transaction.user_id 
           OR connections.connection_id = join_circle_transaction.user_id
    ) >= 150 THEN
        RAISE EXCEPTION 'User has reached maximum circle size of 150';
    END IF;

    -- Check if creator has reached circle size limit (150)
    IF (
        SELECT COUNT(*) FROM connections 
        WHERE connections.user_id = join_circle_transaction.creator_id 
           OR connections.connection_id = join_circle_transaction.creator_id
    ) >= 150 THEN
        RAISE EXCEPTION 'Creator has reached maximum circle size of 150';
    END IF;
    
    -- Mark invite code as used
    UPDATE invite_codes 
    SET used_by_id = join_circle_transaction.user_id 
    WHERE id = invite_id;
    
    -- Create single connection row (always put the smaller UUID first for consistency)
    INSERT INTO connections (user_id, connection_id) VALUES 
    (
        CASE 
            WHEN join_circle_transaction.user_id < join_circle_transaction.creator_id 
            THEN join_circle_transaction.user_id 
            ELSE join_circle_transaction.creator_id 
        END,
        CASE 
            WHEN join_circle_transaction.user_id < join_circle_transaction.creator_id 
            THEN join_circle_transaction.creator_id 
            ELSE join_circle_transaction.user_id 
        END
    );
END;
$$;


-- 8.2 Update get_user_feed (date version) with is_lockout_post
CREATE OR REPLACE FUNCTION public.get_user_feed(
    p_user_id uuid, 
    target_date date, 
    page_size integer DEFAULT 15, 
    page_offset integer DEFAULT 0, 
    cursor_before timestamp with time zone DEFAULT NULL::timestamp with time zone, 
    cursor_after timestamp with time zone DEFAULT NULL::timestamp with time zone
) RETURNS TABLE(
    id uuid, 
    author_id uuid, 
    author_username text, 
    thumbnail_url text, 
    thumbnail_width integer, 
    thumbnail_height integer, 
    content_date date, 
    description text, 
    content_type text, 
    parent_id uuid, 
    parent_author_id uuid, 
    parent_thumbnail_url text, 
    parent_author_username text, 
    parent_content_type text, 
    parent_deleted_at timestamp with time zone, 
    video_url text, 
    created_at timestamp with time zone, 
    updated_at timestamp with time zone, 
    deleted_at timestamp with time zone, 
    published_at timestamp with time zone, 
    published_timezone text, 
    tagged_usernames text, 
    tagged_user_ids text, 
    excluded_user_ids text, 
    parent_excluded_user_ids text, 
    is_author_connected boolean,
    is_lockout_post boolean
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN

IF cursor_after IS NOT NULL THEN
    RETURN QUERY
    SELECT
        p.id,
        p.author_id,
        prof.username AS author_username,
        p.thumbnail_url,
        p.thumbnail_width,
        p.thumbnail_height,
        p.content_date,
        p.description,
        p.content_type::text,
        p.parent_id,
        parent_post.author_id AS parent_author_id,
        parent_post.thumbnail_url AS parent_thumbnail_url,
        parent_prof.username AS parent_author_username,
        parent_post.content_type::text AS parent_content_type,
        parent_post.deleted_at AS parent_deleted_at,
        (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
        p.created_at,
        p.updated_at,
        p.deleted_at,
        p.published_at,
        p.published_timezone,
        STRING_AGG(DISTINCT tagged_prof.username, ', ' ORDER BY tagged_prof.username) AS tagged_usernames,
        STRING_AGG(DISTINCT tagged_prof.id::TEXT, ', ' ORDER BY tagged_prof.id::TEXT) AS tagged_user_ids,
        STRING_AGG(DISTINCT pe.excluded_user_id::TEXT, ', ') AS excluded_user_ids,
        STRING_AGG(DISTINCT parent_pe.excluded_user_id::TEXT, ', ') AS parent_excluded_user_ids,
        (p.author_id = p_user_id OR EXISTS (
            SELECT 1 FROM connections c
            WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
               OR (c.user_id = p.author_id AND c.connection_id = p_user_id)
        )) AS is_author_connected,
        p.is_lockout_post AS is_lockout_post
    FROM posts p
    INNER JOIN profiles prof ON p.author_id = prof.id
    LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
    LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
    LEFT JOIN post_tags pt ON p.id = pt.post_id
    LEFT JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
    LEFT JOIN post_exclusions pe ON p.id = pe.post_id
    LEFT JOIN post_exclusions parent_pe ON parent_post.id = parent_pe.post_id
    WHERE
        p.status = 'published'
        AND p.deleted_at IS NULL
        AND p.created_at > cursor_after
        AND p.content_date = target_date
        AND (
            p.author_id = p_user_id
            OR EXISTS (
                SELECT 1 FROM connections c
                WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
                   OR (c.connection_id = p_user_id AND c.user_id = p.author_id)
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM post_exclusions pe2
            WHERE pe2.post_id = p.id AND pe2.excluded_user_id = p_user_id
        )
    GROUP BY p.id, p.author_id, prof.username, p.thumbnail_url,
             p.thumbnail_width, p.thumbnail_height,
             p.content_date, p.description, p.content_type, p.parent_id,
             parent_post.author_id, parent_post.thumbnail_url, parent_prof.username, parent_post.content_type,
             parent_post.deleted_at,
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone,
             p.is_lockout_post
    ORDER BY p.created_at DESC
    LIMIT page_size;

ELSIF cursor_before IS NOT NULL THEN
    RETURN QUERY
    SELECT
        p.id,
        p.author_id,
        prof.username AS author_username,
        p.thumbnail_url,
        p.thumbnail_width,
        p.thumbnail_height,
        p.content_date,
        p.description,
        p.content_type::text,
        p.parent_id,
        parent_post.author_id AS parent_author_id,
        parent_post.thumbnail_url AS parent_thumbnail_url,
        parent_prof.username AS parent_author_username,
        parent_post.content_type::text AS parent_content_type,
        parent_post.deleted_at AS parent_deleted_at,
        (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
        p.created_at,
        p.updated_at,
        p.deleted_at,
        p.published_at,
        p.published_timezone,
        STRING_AGG(DISTINCT tagged_prof.username, ', ' ORDER BY tagged_prof.username) AS tagged_usernames,
        STRING_AGG(DISTINCT tagged_prof.id::TEXT, ', ' ORDER BY tagged_prof.id::TEXT) AS tagged_user_ids,
        STRING_AGG(DISTINCT pe.excluded_user_id::TEXT, ', ') AS excluded_user_ids,
        STRING_AGG(DISTINCT parent_pe.excluded_user_id::TEXT, ', ') AS parent_excluded_user_ids,
        (p.author_id = p_user_id OR EXISTS (
            SELECT 1 FROM connections c
            WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
               OR (c.user_id = p.author_id AND c.connection_id = p_user_id)
        )) AS is_author_connected,
        p.is_lockout_post AS is_lockout_post
    FROM posts p
    INNER JOIN profiles prof ON p.author_id = prof.id
    LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
    LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
    LEFT JOIN post_tags pt ON p.id = pt.post_id
    LEFT JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
    LEFT JOIN post_exclusions pe ON p.id = pe.post_id
    LEFT JOIN post_exclusions parent_pe ON parent_post.id = parent_pe.post_id
    WHERE
        p.status = 'published'
        AND p.deleted_at IS NULL
        AND p.created_at < cursor_before
        AND p.content_date = target_date
        AND (
            p.author_id = p_user_id
            OR EXISTS (
                SELECT 1 FROM connections c
                WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
                   OR (c.connection_id = p_user_id AND c.user_id = p.author_id)
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM post_exclusions pe2
            WHERE pe2.post_id = p.id AND pe2.excluded_user_id = p_user_id
        )
    GROUP BY p.id, p.author_id, prof.username, p.thumbnail_url,
             p.thumbnail_width, p.thumbnail_height,
             p.content_date, p.description, p.content_type, p.parent_id,
             parent_post.author_id, parent_post.thumbnail_url, parent_prof.username, parent_post.content_type,
             parent_post.deleted_at,
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone,
             p.is_lockout_post
    ORDER BY p.created_at DESC
    LIMIT page_size;

ELSE
    RETURN QUERY
    SELECT
        p.id,
        p.author_id,
        prof.username AS author_username,
        p.thumbnail_url,
        p.thumbnail_width,
        p.thumbnail_height,
        p.content_date,
        p.description,
        p.content_type::text,
        p.parent_id,
        parent_post.author_id AS parent_author_id,
        parent_post.thumbnail_url AS parent_thumbnail_url,
        parent_prof.username AS parent_author_username,
        parent_post.content_type::text AS parent_content_type,
        parent_post.deleted_at AS parent_deleted_at,
        (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
        p.created_at,
        p.updated_at,
        p.deleted_at,
        p.published_at,
        p.published_timezone,
        STRING_AGG(DISTINCT tagged_prof.username, ', ' ORDER BY tagged_prof.username) AS tagged_usernames,
        STRING_AGG(DISTINCT tagged_prof.id::TEXT, ', ' ORDER BY tagged_prof.id::TEXT) AS tagged_user_ids,
        STRING_AGG(DISTINCT pe.excluded_user_id::TEXT, ', ') AS excluded_user_ids,
        STRING_AGG(DISTINCT parent_pe.excluded_user_id::TEXT, ', ') AS parent_excluded_user_ids,
        (p.author_id = p_user_id OR EXISTS (
            SELECT 1 FROM connections c
            WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
               OR (c.user_id = p.author_id AND c.connection_id = p_user_id)
        )) AS is_author_connected,
        p.is_lockout_post AS is_lockout_post
    FROM posts p
    INNER JOIN profiles prof ON p.author_id = prof.id
    LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
    LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
    LEFT JOIN post_tags pt ON p.id = pt.post_id
    LEFT JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
    LEFT JOIN post_exclusions pe ON p.id = pe.post_id
    LEFT JOIN post_exclusions parent_pe ON parent_post.id = parent_pe.post_id
    WHERE
        p.status = 'published'
        AND p.deleted_at IS NULL
        AND p.content_date = target_date
        AND (
            p.author_id = p_user_id
            OR EXISTS (
                SELECT 1 FROM connections c
                WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
                   OR (c.connection_id = p_user_id AND c.user_id = p.author_id)
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM post_exclusions pe2
            WHERE pe2.post_id = p.id AND pe2.excluded_user_id = p_user_id
        )
    GROUP BY p.id, p.author_id, prof.username, p.thumbnail_url,
             p.thumbnail_width, p.thumbnail_height,
             p.content_date, p.description, p.content_type, p.parent_id,
             parent_post.author_id, parent_post.thumbnail_url, parent_prof.username, parent_post.content_type,
             parent_post.deleted_at,
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone,
             p.is_lockout_post
    ORDER BY p.created_at DESC
    LIMIT page_size OFFSET page_offset;

END IF;

END;
$$;


-- 8.3 Create get_user_feed_count (timestamp overload for 24h window)
CREATE OR REPLACE FUNCTION public.get_user_feed_count(
    p_user_id uuid, 
    target_timestamp timestamp with time zone
) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER
AS $$DECLARE
  total_count integer;
BEGIN
  SELECT COUNT(*)::integer
  INTO total_count
  FROM posts p
  WHERE
    p.status = 'published'
    AND p.deleted_at IS NULL
    AND p.created_at >= (target_timestamp - INTERVAL '24 hours')
    AND p.created_at <= target_timestamp
    AND (
      -- I tuoi propri post
      p.author_id = p_user_id
      OR
      -- Post degli utenti nella TUA cerchia
      p.author_id IN (
        SELECT c.connection_id FROM connections c
        WHERE c.user_id = p_user_id
      )
    )
    AND NOT EXISTS (
      SELECT 1 FROM post_exclusions pe
      WHERE pe.post_id = p.id AND pe.excluded_user_id = p_user_id
    );
    
  RETURN total_count;
END;$$;


-- 8.4 Create get_user_feed (timestamp version for 24h rolling window with is_lockout_post)
CREATE OR REPLACE FUNCTION public.get_user_feed(
    p_user_id uuid, 
    target_timestamp timestamp with time zone, 
    page_size integer DEFAULT 15, 
    page_offset integer DEFAULT 0, 
    cursor_before timestamp with time zone DEFAULT NULL::timestamp with time zone, 
    cursor_after timestamp with time zone DEFAULT NULL::timestamp with time zone
) RETURNS TABLE(
    id uuid, 
    author_id uuid, 
    author_username text, 
    thumbnail_url text, 
    thumbnail_width integer, 
    thumbnail_height integer, 
    content_date date, 
    description text, 
    content_type text, 
    parent_id uuid, 
    parent_author_id uuid, 
    parent_thumbnail_url text, 
    parent_author_username text, 
    parent_content_type text, 
    parent_deleted_at timestamp with time zone, 
    video_url text, 
    created_at timestamp with time zone, 
    updated_at timestamp with time zone, 
    deleted_at timestamp with time zone, 
    published_at timestamp with time zone, 
    published_timezone text, 
    tagged_usernames text, 
    tagged_user_ids text, 
    excluded_user_ids text, 
    parent_excluded_user_ids text, 
    is_author_connected boolean,
    is_lockout_post boolean
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN

IF cursor_after IS NOT NULL THEN
    RETURN QUERY
    SELECT
        p.id,
        p.author_id,
        prof.username AS author_username,
        p.thumbnail_url,
        p.thumbnail_width,
        p.thumbnail_height,
        p.content_date,
        p.description,
        p.content_type::text,
        p.parent_id,
        parent_post.author_id AS parent_author_id,
        parent_post.thumbnail_url AS parent_thumbnail_url,
        parent_prof.username AS parent_author_username,
        parent_post.content_type::text AS parent_content_type,
        parent_post.deleted_at AS parent_deleted_at,
        (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
        p.created_at,
        p.updated_at,
        p.deleted_at,
        p.published_at,
        p.published_timezone,
        STRING_AGG(DISTINCT tagged_prof.username, ', ' ORDER BY tagged_prof.username) AS tagged_usernames,
        STRING_AGG(DISTINCT tagged_prof.id::TEXT, ', ' ORDER BY tagged_prof.id::TEXT) AS tagged_user_ids,
        STRING_AGG(DISTINCT pe.excluded_user_id::TEXT, ', ') AS excluded_user_ids,
        STRING_AGG(DISTINCT parent_pe.excluded_user_id::TEXT, ', ') AS parent_excluded_user_ids,
        (p.author_id = p_user_id OR EXISTS (
            SELECT 1 FROM connections c
            WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
               OR (c.user_id = p.author_id AND c.connection_id = p_user_id)
        )) AS is_author_connected,
        p.is_lockout_post
    FROM posts p
    INNER JOIN profiles prof ON p.author_id = prof.id
    LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
    LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
    LEFT JOIN post_tags pt ON p.id = pt.post_id
    LEFT JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
    LEFT JOIN post_exclusions pe ON p.id = pe.post_id
    LEFT JOIN post_exclusions parent_pe ON parent_post.id = parent_pe.post_id
    WHERE
        p.status = 'published'
        AND p.deleted_at IS NULL
        AND p.created_at > cursor_after
        AND p.created_at >= (target_timestamp - INTERVAL '24 hours')
        AND p.created_at <= target_timestamp
        AND (
            p.author_id = p_user_id
            OR EXISTS (
                SELECT 1 FROM connections c
                WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
                   OR (c.connection_id = p_user_id AND c.user_id = p.author_id)
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM post_exclusions pe2
            WHERE pe2.post_id = p.id AND pe2.excluded_user_id = p_user_id
        )
    GROUP BY p.id, p.author_id, prof.username, p.thumbnail_url,
             p.thumbnail_width, p.thumbnail_height,
             p.content_date, p.description, p.content_type, p.parent_id,
             parent_post.author_id, parent_post.thumbnail_url, parent_prof.username, parent_post.content_type,
             parent_post.deleted_at,
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone, p.is_lockout_post
    ORDER BY p.created_at DESC
    LIMIT page_size;

ELSIF cursor_before IS NOT NULL THEN
    RETURN QUERY
    SELECT
        p.id,
        p.author_id,
        prof.username AS author_username,
        p.thumbnail_url,
        p.thumbnail_width,
        p.thumbnail_height,
        p.content_date,
        p.description,
        p.content_type::text,
        p.parent_id,
        parent_post.author_id AS parent_author_id,
        parent_post.thumbnail_url AS parent_thumbnail_url,
        parent_prof.username AS parent_author_username,
        parent_post.content_type::text AS parent_content_type,
        parent_post.deleted_at AS parent_deleted_at,
        (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
        p.created_at,
        p.updated_at,
        p.deleted_at,
        p.published_at,
        p.published_timezone,
        STRING_AGG(DISTINCT tagged_prof.username, ', ' ORDER BY tagged_prof.username) AS tagged_usernames,
        STRING_AGG(DISTINCT tagged_prof.id::TEXT, ', ' ORDER BY tagged_prof.id::TEXT) AS tagged_user_ids,
        STRING_AGG(DISTINCT pe.excluded_user_id::TEXT, ', ') AS excluded_user_ids,
        STRING_AGG(DISTINCT parent_pe.excluded_user_id::TEXT, ', ') AS parent_excluded_user_ids,
        (p.author_id = p_user_id OR EXISTS (
            SELECT 1 FROM connections c
            WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
               OR (c.user_id = p.author_id AND c.connection_id = p_user_id)
        )) AS is_author_connected,
        p.is_lockout_post
    FROM posts p
    INNER JOIN profiles prof ON p.author_id = prof.id
    LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
    LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
    LEFT JOIN post_tags pt ON p.id = pt.post_id
    LEFT JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
    LEFT JOIN post_exclusions pe ON p.id = pe.post_id
    LEFT JOIN post_exclusions parent_pe ON parent_post.id = parent_pe.post_id
    WHERE
        p.status = 'published'
        AND p.deleted_at IS NULL
        AND p.created_at < cursor_before
        AND p.created_at >= (target_timestamp - INTERVAL '24 hours')
        AND p.created_at <= target_timestamp
        AND (
            p.author_id = p_user_id
            OR EXISTS (
                SELECT 1 FROM connections c
                WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
                   OR (c.connection_id = p_user_id AND c.user_id = p.author_id)
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM post_exclusions pe2
            WHERE pe2.post_id = p.id AND pe2.excluded_user_id = p_user_id
        )
    GROUP BY p.id, p.author_id, prof.username, p.thumbnail_url,
             p.thumbnail_width, p.thumbnail_height,
             p.content_date, p.description, p.content_type, p.parent_id,
             parent_post.author_id, parent_post.thumbnail_url, parent_prof.username, parent_post.content_type,
             parent_post.deleted_at,
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone, p.is_lockout_post
    ORDER BY p.created_at DESC
    LIMIT page_size;

ELSE
    RETURN QUERY
    SELECT
        p.id,
        p.author_id,
        prof.username AS author_username,
        p.thumbnail_url,
        p.thumbnail_width,
        p.thumbnail_height,
        p.content_date,
        p.description,
        p.content_type::text,
        p.parent_id,
        parent_post.author_id AS parent_author_id,
        parent_post.thumbnail_url AS parent_thumbnail_url,
        parent_prof.username AS parent_author_username,
        parent_post.content_type::text AS parent_content_type,
        parent_post.deleted_at AS parent_deleted_at,
        (SELECT pm.media_url FROM post_media pm WHERE pm.post_id = p.id AND pm.media_type = 'video' LIMIT 1) AS video_url,
        p.created_at,
        p.updated_at,
        p.deleted_at,
        p.published_at,
        p.published_timezone,
        STRING_AGG(DISTINCT tagged_prof.username, ', ' ORDER BY tagged_prof.username) AS tagged_usernames,
        STRING_AGG(DISTINCT tagged_prof.id::TEXT, ', ' ORDER BY tagged_prof.id::TEXT) AS tagged_user_ids,
        STRING_AGG(DISTINCT pe.excluded_user_id::TEXT, ', ') AS excluded_user_ids,
        STRING_AGG(DISTINCT parent_pe.excluded_user_id::TEXT, ', ') AS parent_excluded_user_ids,
        (p.author_id = p_user_id OR EXISTS (
            SELECT 1 FROM connections c
            WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
               OR (c.user_id = p.author_id AND c.connection_id = p_user_id)
        )) AS is_author_connected,
        p.is_lockout_post
    FROM posts p
    INNER JOIN profiles prof ON p.author_id = prof.id
    LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
    LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
    LEFT JOIN post_tags pt ON p.id = pt.post_id
    LEFT JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
    LEFT JOIN post_exclusions pe ON p.id = pe.post_id
    LEFT JOIN post_exclusions parent_pe ON parent_post.id = parent_pe.post_id
    WHERE
        p.status = 'published'
        AND p.deleted_at IS NULL
        AND p.created_at >= (target_timestamp - INTERVAL '24 hours')
        AND p.created_at <= target_timestamp
        AND (
            p.author_id = p_user_id
            OR EXISTS (
                SELECT 1 FROM connections c
                WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
                   OR (c.connection_id = p_user_id AND c.user_id = p.author_id)
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM post_exclusions pe2
            WHERE pe2.post_id = p.id AND pe2.excluded_user_id = p_user_id
        )
    GROUP BY p.id, p.author_id, prof.username, p.thumbnail_url,
             p.thumbnail_width, p.thumbnail_height,
             p.content_date, p.description, p.content_type, p.parent_id,
             parent_post.author_id, parent_post.thumbnail_url, parent_prof.username, parent_post.content_type,
             parent_post.deleted_at,
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone, p.is_lockout_post
    ORDER BY p.created_at DESC
    LIMIT page_size OFFSET page_offset;

END IF;

END;
$$;


-- 8.5 Update get_post_by_id with is_lockout_post
CREATE OR REPLACE FUNCTION public.get_post_by_id(p_post_id uuid, p_user_id uuid) 
RETURNS TABLE(
    id uuid, 
    author_id uuid, 
    author_username text, 
    author_avatar_url text, 
    content_type text, 
    description text, 
    thumbnail_url text, 
    thumbnail_width integer, 
    thumbnail_height integer, 
    content_date date, 
    video_url text, 
    parent_id uuid, 
    parent_author_id uuid, 
    parent_thumbnail_url text, 
    parent_author_username text, 
    parent_content_type text, 
    parent_deleted_at timestamp with time zone, 
    status text, 
    published_at timestamp with time zone, 
    published_timezone text, 
    created_at timestamp with time zone, 
    updated_at timestamp with time zone, 
    tagged_user_ids text, 
    tagged_usernames text, 
    excluded_user_ids text, 
    parent_excluded_user_ids text, 
    is_author_connected boolean,
    is_lockout_post boolean
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.author_id,
    prof.username AS author_username,
    NULL::TEXT AS author_avatar_url,
    p.content_type::TEXT,
    p.description,
    p.thumbnail_url,
    p.thumbnail_width,
    p.thumbnail_height,
    p.content_date,
    COALESCE(
      (SELECT pm.media_url 
       FROM post_media pm 
       WHERE pm.post_id = p.id 
         AND pm.media_type = 'video' 
       LIMIT 1),
      NULL
    ) AS video_url,
    p.parent_id,
    parent_post.author_id AS parent_author_id,
    parent_post.thumbnail_url AS parent_thumbnail_url,
    parent_prof.username AS parent_author_username,
    parent_post.content_type::TEXT AS parent_content_type,
    parent_post.deleted_at AS parent_deleted_at,
    p.status::TEXT,
    p.published_at,                  
    p.published_timezone,             
    p.created_at,
    p.updated_at,
    COALESCE(
      (SELECT STRING_AGG(pt.tagged_user_id::TEXT, ',')
       FROM post_tags pt
       WHERE pt.post_id = p.id),
      NULL
    ) AS tagged_user_ids,
    COALESCE(
      (SELECT STRING_AGG(tagged_prof.username, ',')
       FROM post_tags pt
       JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
       WHERE pt.post_id = p.id),
      NULL
    ) AS tagged_usernames,
    COALESCE(
      (SELECT STRING_AGG(pe.excluded_user_id::TEXT, ',')
       FROM post_exclusions pe
       WHERE pe.post_id = p.id),
      NULL
    ) AS excluded_user_ids,
    COALESCE(
      (SELECT STRING_AGG(parent_pe.excluded_user_id::TEXT, ',')
       FROM post_exclusions parent_pe
       WHERE parent_pe.post_id = p.parent_id),
      NULL
    ) AS parent_excluded_user_ids,
    (p.author_id = p_user_id OR EXISTS (
      SELECT 1 FROM connections c
      WHERE (c.user_id = p_user_id AND c.connection_id = p.author_id)
         OR (c.user_id = p.author_id AND c.connection_id = p_user_id)
    )) AS is_author_connected,
    p.is_lockout_post
  FROM posts p
  JOIN profiles prof ON p.author_id = prof.id
  LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
  LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
  WHERE p.id = p_post_id
    AND p.status = 'published'
    AND (
      p.author_id = p_user_id
      OR NOT EXISTS (
        SELECT 1 FROM post_exclusions pe
        WHERE pe.post_id = p.id AND pe.excluded_user_id = p_user_id
      )
    );
END;
$$;


-- ================================================================================
-- SECTION 9: TRIGGERS
-- ================================================================================

-- Drop triggers if they exist (to make migration idempotent)
DROP TRIGGER IF EXISTS on_reaction_created ON public.post_reactions;
DROP TRIGGER IF EXISTS on_tag_created ON public.post_tags;
DROP TRIGGER IF EXISTS on_reply_created ON public.posts;
DROP TRIGGER IF EXISTS on_reply_published ON public.posts;
DROP TRIGGER IF EXISTS on_connection_created ON public.connections;

-- Create notification triggers
CREATE TRIGGER on_reaction_created
AFTER INSERT ON public.post_reactions
FOR EACH ROW EXECUTE FUNCTION public.create_reaction_notification();

CREATE TRIGGER on_tag_created
AFTER INSERT ON public.post_tags
FOR EACH ROW EXECUTE FUNCTION public.create_tag_notification();

CREATE TRIGGER on_reply_created
AFTER INSERT ON public.posts
FOR EACH ROW
WHEN (NEW.parent_id IS NOT NULL)
EXECUTE FUNCTION public.create_reply_notification();

CREATE TRIGGER on_reply_published
AFTER UPDATE ON public.posts
FOR EACH ROW
WHEN (NEW.parent_id IS NOT NULL)
EXECUTE FUNCTION public.create_reply_notification_on_update();

CREATE TRIGGER on_connection_created
AFTER INSERT ON public.connections
FOR EACH ROW EXECUTE FUNCTION public.create_circle_join_notification();


-- ================================================================================
-- SECTION 10: GRANTS
-- ================================================================================

-- Grants for notifications table
GRANT ALL ON TABLE public.notifications TO anon;
GRANT ALL ON TABLE public.notifications TO authenticated;
GRANT ALL ON TABLE public.notifications TO service_role;

-- Grants for new functions
GRANT ALL ON FUNCTION public.check_phone_numbers_exist(text[]) TO anon;
GRANT ALL ON FUNCTION public.check_phone_numbers_exist(text[]) TO authenticated;
GRANT ALL ON FUNCTION public.check_phone_numbers_exist(text[]) TO service_role;

GRANT ALL ON FUNCTION public.cleanup_old_read_notifications() TO anon;
GRANT ALL ON FUNCTION public.cleanup_old_read_notifications() TO authenticated;
GRANT ALL ON FUNCTION public.cleanup_old_read_notifications() TO service_role;

GRANT ALL ON FUNCTION public.create_reaction_notification() TO anon;
GRANT ALL ON FUNCTION public.create_reaction_notification() TO authenticated;
GRANT ALL ON FUNCTION public.create_reaction_notification() TO service_role;

GRANT ALL ON FUNCTION public.create_tag_notification() TO anon;
GRANT ALL ON FUNCTION public.create_tag_notification() TO authenticated;
GRANT ALL ON FUNCTION public.create_tag_notification() TO service_role;

GRANT ALL ON FUNCTION public.create_reply_notification() TO anon;
GRANT ALL ON FUNCTION public.create_reply_notification() TO authenticated;
GRANT ALL ON FUNCTION public.create_reply_notification() TO service_role;

GRANT ALL ON FUNCTION public.create_reply_notification_on_update() TO anon;
GRANT ALL ON FUNCTION public.create_reply_notification_on_update() TO authenticated;
GRANT ALL ON FUNCTION public.create_reply_notification_on_update() TO service_role;

GRANT ALL ON FUNCTION public.create_circle_join_notification() TO anon;
GRANT ALL ON FUNCTION public.create_circle_join_notification() TO authenticated;
GRANT ALL ON FUNCTION public.create_circle_join_notification() TO service_role;

GRANT ALL ON FUNCTION public.get_aggregated_notifications(uuid, integer, integer) TO anon;
GRANT ALL ON FUNCTION public.get_aggregated_notifications(uuid, integer, integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_aggregated_notifications(uuid, integer, integer) TO service_role;

GRANT ALL ON FUNCTION public.get_user_feed_count(uuid, timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.get_user_feed_count(uuid, timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_feed_count(uuid, timestamp with time zone) TO service_role;

GRANT ALL ON FUNCTION public.get_user_feed(uuid, timestamp with time zone, integer, integer, timestamp with time zone, timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.get_user_feed(uuid, timestamp with time zone, integer, integer, timestamp with time zone, timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_feed(uuid, timestamp with time zone, integer, integer, timestamp with time zone, timestamp with time zone) TO service_role;


-- ================================================================================
-- MIGRATION COMPLETE
-- ================================================================================
-- Summary of changes:
-- 1. Added 'text' value to content_type enum
-- 2. Added is_lockout_post column to posts table
-- 3. Created notifications table with indexes, foreign keys, RLS policies
-- 4. Created new functions:
--    - check_phone_numbers_exist(text[])
--    - cleanup_old_read_notifications()
--    - create_reaction_notification()
--    - create_tag_notification()
--    - create_reply_notification()
--    - create_reply_notification_on_update()
--    - create_circle_join_notification()
--    - get_aggregated_notifications(uuid, integer, integer)
-- 5. Updated functions:
--    - join_circle_transaction() - added circle size limit checks (150)
--    - get_user_feed() - date version with is_lockout_post
--    - get_user_feed() - timestamp version for 24h rolling window
--    - get_user_feed_count() - timestamp overload for 24h window
--    - get_post_by_id() - with is_lockout_post
-- 6. Created notification triggers
-- 7. Applied all necessary grants
-- ================================================================================
