-- Migration: Change feed filtering from calendar date to 24-hour rolling window
-- This migration modifies get_user_feed and get_user_feed_count functions to filter posts
-- based on created_at timestamp with a 24-hour rolling window, instead of filtering by content_date
-- at calendar day boundaries (midnight reset).

-- Modify get_user_feed function to use timestamp-based 24-hour window
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
    is_author_connected boolean
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
        )) AS is_author_connected
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
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone
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
        )) AS is_author_connected
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
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone
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
        )) AS is_author_connected
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
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone
    ORDER BY p.created_at DESC
    LIMIT page_size OFFSET page_offset;

END IF;

END;
$$;

-- Modify get_user_feed_count function to use timestamp-based 24-hour window
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

