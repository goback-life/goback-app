--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: content_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.content_type AS ENUM (
    'image',
    'audio',
    'video',
    'double_image'
);


--
-- Name: post_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_status AS ENUM (
    'draft',
    'published',
    'failed'
);


--
-- Name: add_post_to_calendar(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_post_to_calendar(p_post_id uuid, p_calendar_date date) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_user_id UUID;
  v_post_author_id UUID;
  v_existing_post_id UUID;
BEGIN
  -- Ottieni user_id corrente
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not authenticated'
    );
  END IF;

  -- Verifica che il post esista e appartenga all'utente
  SELECT author_id INTO v_post_author_id
  FROM posts
  WHERE id = p_post_id AND status = 'published';

  IF v_post_author_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Post not found'
    );
  END IF;

  IF v_post_author_id != v_user_id THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Cannot add other users posts to calendar'
    );
  END IF;

  -- Verifica se esiste già un post per quella data
  SELECT post_id INTO v_existing_post_id
  FROM calendar_posts
  WHERE user_id = v_user_id AND calendar_date = p_calendar_date;

  IF v_existing_post_id IS NOT NULL THEN
    -- Se è lo stesso post, non fare nulla
    IF v_existing_post_id = p_post_id THEN
      RETURN json_build_object(
        'success', true,
        'message', 'Post already in calendar for this date'
      );
    END IF;

    -- Altrimenti sostituisci il post esistente
    UPDATE calendar_posts
    SET post_id = p_post_id, created_at = now()
    WHERE user_id = v_user_id AND calendar_date = p_calendar_date;

    RETURN json_build_object(
      'success', true,
      'message', 'Calendar post updated'
    );
  ELSE
    -- Inserisci nuovo post in calendario
    INSERT INTO calendar_posts (user_id, post_id, calendar_date)
    VALUES (v_user_id, p_post_id, p_calendar_date);

    RETURN json_build_object(
      'success', true,
      'message', 'Post added to calendar'
    );
  END IF;
END;
$$;


--
-- Name: check_duplicate_report(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_duplicate_report(p_post_id uuid, p_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.post_reports
        WHERE post_id = p_post_id
        AND reported_by = p_user_id
    );
END;
$$;


--
-- Name: check_invite_codes_limit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_invite_codes_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  active_count integer;
BEGIN
  SELECT COUNT(*) INTO active_count
  FROM public.invite_codes
  WHERE creator_id = NEW.creator_id
    AND used_by_id IS NULL
    AND expires_at > now();

  IF active_count >= 100 THEN
    RAISE EXCEPTION 'Limite di 100 codici attivi raggiunto per questo utente';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: check_post_in_calendar(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_post_in_calendar(p_calendar_date date) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_user_id UUID;
  v_post_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'in_calendar', false,
      'post_id', null
    );
  END IF;

  SELECT post_id INTO v_post_id
  FROM calendar_posts
  WHERE user_id = v_user_id AND calendar_date = p_calendar_date;

  RETURN json_build_object(
    'in_calendar', (v_post_id IS NOT NULL),
    'post_id', v_post_id
  );
END;
$$;


--
-- Name: cleanup_expired_invites(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_expired_invites() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.invite_codes
  WHERE expires_at < now() - interval '7 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;


--
-- Name: cleanup_old_drafts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_old_drafts() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
  delete from public.posts
  where status in ('draft', 'failed')
    and created_at < now() - interval '24 hours';
end;
$$;


--
-- Name: cleanup_storage_files(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_storage_files(file_paths text[]) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  file_path text;
  deleted_count integer := 0;
  failed_count integer := 0;
  errors text[] := ARRAY[]::text[];
BEGIN
  FOREACH file_path IN ARRAY file_paths
  LOOP
    BEGIN
      IF file_path IS NULL OR file_path = '' THEN
        CONTINUE;
      END IF;
      
      DELETE FROM storage.objects 
      WHERE bucket_id = 'post_media' 
        AND name = file_path;
      
      IF FOUND THEN
        deleted_count := deleted_count + 1;
        RAISE NOTICE 'Deleted file: %', file_path;
      ELSE
        failed_count := failed_count + 1;
        errors := errors || ('File not found: ' || file_path);
        RAISE WARNING 'File not found in storage: %', file_path;
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        failed_count := failed_count + 1;
        errors := errors || (file_path || ': ' || SQLERRM);
        RAISE WARNING 'Error deleting file %: %', file_path, SQLERRM;
    END;
  END LOOP;
  
  RETURN json_build_object(
    'success', true,
    'deleted_count', deleted_count,
    'failed_count', failed_count,
    'errors', errors,
    'execution_time', NOW() AT TIME ZONE 'UTC'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM,
      'execution_time', NOW() AT TIME ZONE 'UTC'
    );
END;
$$;


--
-- Name: create_bidirectional_connection(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_bidirectional_connection(user_a uuid, user_b uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.connections (user_id, connection_id)
  VALUES (user_a, user_b)
  ON CONFLICT (user_id, connection_id) DO NOTHING;

  INSERT INTO public.connections (user_id, connection_id)
  VALUES (user_b, user_a)
  ON CONFLICT (user_id, connection_id) DO NOTHING;
END;
$$;


--
-- Name: delete_current_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_current_user() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  current_user_id uuid;
  posts_soft_deleted INTEGER;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Nessun utente autenticato';
  END IF;

  -- STEP 1: Soft delete posts (con privilegi utente)
  SELECT soft_delete_user_posts() INTO posts_soft_deleted;
  
  -- STEP 2: DISSOCIA i posts dall'utente PRIMA del CASCADE
  -- Imposta author_id a NULL per evitare che vengano eliminati dal CASCADE
  UPDATE public.posts 
  SET author_id = NULL 
  WHERE author_id = current_user_id;
  
  -- STEP 3: Pulisci altre tabelle
  DELETE FROM public.connections
  WHERE user_id = current_user_id OR connection_id = current_user_id;

  DELETE FROM public.invite_codes
  WHERE creator_id = current_user_id;

  UPDATE public.invite_codes
  SET used_by_id = NULL
  WHERE used_by_id = current_user_id;

  DELETE FROM storage.objects
  WHERE bucket_id = 'avatars' 
    AND name = current_user_id::text;

  DELETE FROM auth.users WHERE id = current_user_id;

  RAISE NOTICE 'Utente % e profilo eliminati. Posts soft deleted e dissociati: %', current_user_id, posts_soft_deleted;
END;$$;


--
-- Name: delete_old_posts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_old_posts() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  cutoff_date timestamptz;
  deleted_posts_count integer := 0;
  soft_deleted_posts_count integer := 0;
  deleted_files text[] := ARRAY[]::text[];
  post_record record;
  media_record record;
  storage_cleanup_result json;
  result json;
BEGIN
  -- Calculate cutoff: 2 days + 2 hours to account for maximum timezone offset
  cutoff_date := (NOW() AT TIME ZONE 'UTC') - INTERVAL '2 days 2 hours';
  
  RAISE NOTICE 'Starting deletion process. Cutoff date: %', cutoff_date;
  
  -- STEP 1: SOFT DELETE - Direct parents of posts saved to calendar
  FOR post_record IN
    SELECT DISTINCT p.id
    FROM posts p
    WHERE p.created_at < cutoff_date
      AND p.deleted_at IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM calendar_posts cp WHERE cp.post_id = p.id
      )
      AND EXISTS (
        SELECT 1 
        FROM posts child
        INNER JOIN calendar_posts cp ON cp.post_id = child.id AND cp.user_id = child.author_id
        WHERE child.parent_id = p.id
      )
  LOOP
    UPDATE posts 
    SET 
      deleted_at = NOW() AT TIME ZONE 'UTC',
      updated_at = NOW() AT TIME ZONE 'UTC'
    WHERE id = post_record.id;
    
    soft_deleted_posts_count := soft_deleted_posts_count + 1;
    RAISE NOTICE 'Soft deleted direct parent: %', post_record.id;
  END LOOP;
  
  -- STEP 2: PHYSICAL DELETE - Posts without protection
  FOR post_record IN
    SELECT DISTINCT p.id, p.thumbnail_url
    FROM posts p
    WHERE p.created_at < cutoff_date
      AND p.deleted_at IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM calendar_posts cp WHERE cp.post_id = p.id
      )
      AND NOT EXISTS (
        SELECT 1 
        FROM posts child
        INNER JOIN calendar_posts cp ON cp.post_id = child.id AND cp.user_id = child.author_id
        WHERE child.parent_id = p.id
      )
  LOOP
    -- Collect thumbnail for deletion (già percorso relativo)
    IF post_record.thumbnail_url IS NOT NULL AND post_record.thumbnail_url != '' THEN
      deleted_files := deleted_files || post_record.thumbnail_url;
      RAISE NOTICE 'Added thumbnail to deletion queue: %', post_record.thumbnail_url;
    END IF;
    
    -- Collect media files for deletion (già percorsi relativi)
    FOR media_record IN
      SELECT media_url FROM post_media WHERE post_id = post_record.id
    LOOP
      IF media_record.media_url IS NOT NULL AND media_record.media_url != '' THEN
        deleted_files := deleted_files || media_record.media_url;
        RAISE NOTICE 'Added media to deletion queue: %', media_record.media_url;
      END IF;
    END LOOP;
    
    -- Physical delete (cascade will handle all descendants not protected)
    DELETE FROM posts WHERE id = post_record.id;
    deleted_posts_count := deleted_posts_count + 1;
    RAISE NOTICE 'Physically deleted post: %', post_record.id;
  END LOOP;
  
  -- STEP 3: Cleanup storage files
  IF array_length(deleted_files, 1) > 0 THEN
    RAISE NOTICE 'Cleaning up % files from storage', array_length(deleted_files, 1);
    
    BEGIN
      SELECT cleanup_storage_files(deleted_files) INTO storage_cleanup_result;
      RAISE NOTICE 'Storage cleanup result: %', storage_cleanup_result;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Storage cleanup failed: %', SQLERRM;
        storage_cleanup_result := json_build_object(
          'success', false,
          'error', SQLERRM
        );
    END;
  ELSE
    RAISE NOTICE 'No files to clean up from storage';
    storage_cleanup_result := json_build_object(
      'success', true,
      'deleted_count', 0,
      'message', 'No files to delete'
    );
  END IF;
  
  -- Build final result
  result := json_build_object(
    'success', true,
    'cutoff_date', cutoff_date,
    'deleted_posts_count', deleted_posts_count,
    'soft_deleted_posts_count', soft_deleted_posts_count,
    'files_deleted_count', COALESCE(array_length(deleted_files, 1), 0),
    'storage_cleanup', storage_cleanup_result,
    'execution_time', NOW() AT TIME ZONE 'UTC'
  );
  
  RAISE NOTICE 'Deletion process completed: %', result;
  
  RETURN result;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Deletion process failed: %', SQLERRM;
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM,
      'error_detail', SQLSTATE,
      'execution_time', NOW() AT TIME ZONE 'UTC'
    );
END;
$$;


--
-- Name: delete_user_by_id(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_user_by_id(user_id_param uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  posts_soft_deleted INTEGER;
BEGIN
  -- Verifica che l'utente esista
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_id_param) THEN
    RAISE EXCEPTION 'Utente % non trovato', user_id_param;
  END IF;

  -- STEP 1: Soft delete posts (simulando l'utente)
  UPDATE public.posts 
  SET deleted_at = NOW() 
  WHERE author_id = user_id_param 
    AND deleted_at IS NULL;
    
  GET DIAGNOSTICS posts_soft_deleted = ROW_COUNT;
  
  -- STEP 2: DISSOCIA i posts dall'utente PRIMA del CASCADE
  UPDATE public.posts 
  SET author_id = NULL 
  WHERE author_id = user_id_param;
  
  -- STEP 3: Pulisci altre tabelle
  DELETE FROM public.connections
  WHERE user_id = user_id_param OR connection_id = user_id_param;

  DELETE FROM public.invite_codes
  WHERE creator_id = user_id_param;

  UPDATE public.invite_codes
  SET used_by_id = NULL
  WHERE used_by_id = user_id_param;

  DELETE FROM storage.objects
  WHERE bucket_id = 'avatars' 
    AND name = user_id_param::text;

  -- STEP 4: Elimina utente (CASCADE eliminerà il profilo)
  DELETE FROM auth.users WHERE id = user_id_param;

  RAISE NOTICE 'Utente % eliminato dall''SQL Editor. Posts soft deleted: %', user_id_param, posts_soft_deleted;
END;
$$;


--
-- Name: get_calendar_posts(uuid, date, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_calendar_posts(p_user_id uuid, p_reference_date date, p_direction text DEFAULT 'before'::text, p_limit integer DEFAULT 42) RETURNS TABLE(calendar_id uuid, calendar_date date, post_id uuid, author_id uuid, author_username text, author_avatar_url text, thumbnail_url text, thumbnail_width integer, thumbnail_height integer, content_date date, description text, content_type text, video_url text, parent_id uuid, parent_author_id uuid, parent_thumbnail_url text, parent_author_username text, parent_content_type text, parent_deleted_at timestamp with time zone, created_at timestamp with time zone, updated_at timestamp with time zone, published_at timestamp with time zone, published_timezone text, tagged_usernames text, tagged_user_ids text, excluded_user_ids text, parent_excluded_user_ids text, is_author_connected boolean, is_own_post boolean, is_today boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id AS calendar_id,
    cp.calendar_date,
    p.id AS post_id,
    p.author_id,
    prof.username AS author_username,
    NULL::TEXT AS author_avatar_url,
    p.thumbnail_url,
    p.thumbnail_width,
    p.thumbnail_height,
    p.content_date,
    p.description,
    p.content_type::TEXT,
    (SELECT pm.media_url 
     FROM post_media pm 
     WHERE pm.post_id = p.id AND pm.media_type = 'video' 
     LIMIT 1) AS video_url,
    p.parent_id,
    parent_post.author_id AS parent_author_id,
    parent_post.thumbnail_url AS parent_thumbnail_url,
    parent_prof.username AS parent_author_username,
    parent_post.content_type::TEXT AS parent_content_type,
    parent_post.deleted_at AS parent_deleted_at,
    p.created_at,
    p.updated_at,
    p.published_at,
    p.published_timezone,
    COALESCE(
      (SELECT STRING_AGG(tagged_prof.username, ', ' ORDER BY tagged_prof.username)
       FROM post_tags pt
       JOIN profiles tagged_prof ON pt.tagged_user_id = tagged_prof.id
       WHERE pt.post_id = p.id),
      NULL
    ) AS tagged_usernames,
    COALESCE(
      (SELECT STRING_AGG(pt.tagged_user_id::TEXT, ', ' ORDER BY pt.tagged_user_id::TEXT)
       FROM post_tags pt
       WHERE pt.post_id = p.id),
      NULL
    ) AS tagged_user_ids,
    COALESCE(
      (SELECT STRING_AGG(pe.excluded_user_id::TEXT, ', ')
       FROM post_exclusions pe
       WHERE pe.post_id = p.id),
      NULL
    ) AS excluded_user_ids,
    COALESCE(
      (SELECT STRING_AGG(parent_pe.excluded_user_id::TEXT, ', ')
       FROM post_exclusions parent_pe
       WHERE parent_pe.post_id = p.parent_id),
      NULL
    ) AS parent_excluded_user_ids,
    (p.author_id = auth.uid() OR EXISTS (
      SELECT 1 FROM connections c
      WHERE (c.user_id = auth.uid() AND c.connection_id = p.author_id)
         OR (c.user_id = p.author_id AND c.connection_id = auth.uid())
    )) AS is_author_connected,
    (p.author_id = auth.uid()) AS is_own_post,
    (cp.calendar_date = CURRENT_DATE) AS is_today
  FROM calendar_posts cp
  INNER JOIN posts p ON cp.post_id = p.id
  INNER JOIN profiles prof ON p.author_id = prof.id
  LEFT JOIN posts parent_post ON p.parent_id = parent_post.id
  LEFT JOIN profiles parent_prof ON parent_post.author_id = parent_prof.id
  WHERE
    cp.user_id = p_user_id
    AND (
      (p_direction = 'before' AND cp.calendar_date <= p_reference_date)
      OR (p_direction = 'after' AND cp.calendar_date > p_reference_date)
    )
    AND p.status = 'published'
    AND p.deleted_at IS NULL
    -- L'utente corrente deve essere connesso al proprietario del calendario
    AND (
      p_user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM connections c
        WHERE (c.user_id = auth.uid() AND c.connection_id = p_user_id)
           OR (c.connection_id = auth.uid() AND c.user_id = p_user_id)
      )
    )
    -- L'utente corrente non deve essere tra gli esclusi dal post
    AND NOT EXISTS (
      SELECT 1 FROM post_exclusions pe
      WHERE pe.post_id = p.id AND pe.excluded_user_id = auth.uid()
    )
  ORDER BY 
    CASE 
      WHEN p_direction = 'before' THEN cp.calendar_date 
    END DESC,
    CASE 
      WHEN p_direction = 'after' THEN cp.calendar_date 
    END ASC
  LIMIT p_limit;
END;
$$;


--
-- Name: get_circle_members(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_circle_members(user_id uuid) RETURNS TABLE(connection_id uuid, id uuid, username text, biography text, phone_number text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN c.user_id = get_circle_members.user_id THEN c.connection_id
            ELSE c.user_id
        END as connection_id,
        p.id,
        p.username,
        p.biography,
        au.phone as phone_number
    FROM connections c
    JOIN profiles p ON (
        CASE 
            WHEN c.user_id = get_circle_members.user_id THEN c.connection_id = p.id
            ELSE c.user_id = p.id
        END
    )
    JOIN auth.users au ON au.id = p.id
    WHERE get_circle_members.user_id = c.user_id OR get_circle_members.user_id = c.connection_id;
END;$$;


--
-- Name: get_post_by_id(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_post_by_id(p_post_id uuid, p_user_id uuid) RETURNS TABLE(id uuid, author_id uuid, author_username text, author_avatar_url text, content_type text, description text, thumbnail_url text, thumbnail_width integer, thumbnail_height integer, content_date date, video_url text, parent_id uuid, parent_author_id uuid, parent_thumbnail_url text, parent_author_username text, parent_content_type text, parent_deleted_at timestamp with time zone, status text, published_at timestamp with time zone, published_timezone text, created_at timestamp with time zone, updated_at timestamp with time zone, tagged_user_ids text, tagged_usernames text, excluded_user_ids text, parent_excluded_user_ids text, is_author_connected boolean)
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
    )) AS is_author_connected
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


--
-- Name: get_user_feed(uuid, date, integer, integer, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_feed(p_user_id uuid, target_date date, page_size integer DEFAULT 15, page_offset integer DEFAULT 0, cursor_before timestamp with time zone DEFAULT NULL::timestamp with time zone, cursor_after timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(id uuid, author_id uuid, author_username text, thumbnail_url text, thumbnail_width integer, thumbnail_height integer, content_date date, description text, content_type text, parent_id uuid, parent_author_id uuid, parent_thumbnail_url text, parent_author_username text, parent_content_type text, parent_deleted_at timestamp with time zone, video_url text, created_at timestamp with time zone, updated_at timestamp with time zone, deleted_at timestamp with time zone, published_at timestamp with time zone, published_timezone text, tagged_usernames text, tagged_user_ids text, excluded_user_ids text, parent_excluded_user_ids text, is_author_connected boolean)
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
             p.created_at, p.updated_at, p.deleted_at, p.published_at, p.published_timezone
    ORDER BY p.created_at DESC
    LIMIT page_size OFFSET page_offset;

END IF;

END;
$$;


--
-- Name: get_user_feed_count(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_feed_count(p_user_id uuid, target_date date) RETURNS integer
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
    AND p.content_date = get_user_feed_count.target_date
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


--
-- Name: join_circle_transaction(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.join_circle_transaction(invite_id uuid, user_id uuid, creator_id uuid) RETURNS void
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


--
-- Name: remove_bidirectional_connection(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_bidirectional_connection(user_a uuid, user_b uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE FROM public.connections
  WHERE (user_id = user_a AND connection_id = user_b)
     OR (user_id = user_b AND connection_id = user_a);
END;
$$;


--
-- Name: remove_deleted_post_from_calendar(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_deleted_post_from_calendar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Se il post viene soft-deleted (deleted_at impostato)
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    -- Rimuovi da tutti i calendari dove è presente
    DELETE FROM calendar_posts
    WHERE post_id = NEW.id;

    RAISE NOTICE 'Post % removed from all calendars', NEW.id;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: remove_post_from_calendar(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_post_from_calendar(p_calendar_date date) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_user_id UUID;
  v_deleted_count INT;
  v_found_post UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not authenticated'
    );
  END IF;

  -- Debug: verifica se esiste un post per questa data prima di eliminarlo
  SELECT post_id INTO v_found_post
  FROM calendar_posts
  WHERE user_id = v_user_id 
    AND calendar_date = p_calendar_date::DATE;

  -- Se non troviamo il post, ritorna comunque success (è già rimosso)
  IF v_found_post IS NULL THEN
    RETURN json_build_object(
      'success', true,
      'message', 'No post found for this date (already removed)'
    );
  END IF;

  -- Elimina il post dal calendario per quella data
  DELETE FROM calendar_posts
  WHERE user_id = v_user_id 
    AND calendar_date = p_calendar_date::DATE;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  RETURN json_build_object(
    'success', true,
    'message', 'Post removed from calendar',
    'deleted_count', v_deleted_count
  );
END;
$$;


--
-- Name: restore_post(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restore_post(post_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    UPDATE public.posts 
    SET deleted_at = NULL 
    WHERE id = post_id 
      AND deleted_at IS NOT NULL;
    
    RETURN FOUND;
END;
$$;


--
-- Name: restore_user_posts(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restore_user_posts(user_uuid uuid) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    posts_restored INTEGER;
BEGIN
    UPDATE public.posts 
    SET deleted_at = NULL 
    WHERE author_id = user_uuid 
      AND deleted_at IS NOT NULL;
    
    GET DIAGNOSTICS posts_restored = ROW_COUNT;
    RETURN posts_restored;
END;
$$;


--
-- Name: send_email_on_new_report(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.send_email_on_new_report() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  function_url text;
  service_role_key text;
BEGIN
  SELECT value INTO STRICT function_url 
  FROM public.app_config 
  WHERE key = 'function_url';
  
  SELECT value INTO STRICT service_role_key 
  FROM public.app_config 
  WHERE key = 'service_role_key';
  
  RAISE NOTICE 'Sending email for report: %', new.id;
  
  PERFORM net.http_post(
    url := function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_role_key
    ),
    body := jsonb_build_object(
      'record', jsonb_build_object(
        'id', new.id::text,
        'post_id', new.post_id::text,
        'reported_by', new.reported_by::text,
        'reason', new.reason,
        'created_at', new.created_at::text
      )
    ),
    timeout_milliseconds := 5000
  );
  
  RAISE NOTICE 'Email sent for report %', new.id;
  
  RETURN new;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    RAISE WARNING 'Configuration not found in app_config table';
    RETURN new;
  WHEN TOO_MANY_ROWS THEN
    RAISE WARNING 'Duplicate configuration keys found in app_config table';
    RETURN new;
  WHEN OTHERS THEN
    RAISE WARNING 'Error sending email for report %: % (SQLSTATE: %)', 
      new.id, SQLERRM, SQLSTATE;
    RETURN new;
END;
$$;


--
-- Name: set_invite_used_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_invite_used_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.used_by_id IS NOT NULL AND OLD.used_by_id IS NULL THEN
    NEW.used_at = now();
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: set_published_at_from_created(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_published_at_from_created() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
  IF NEW.published_at IS NULL THEN
    NEW.published_at = NEW.created_at;
  END IF;
  RETURN NEW;
END;$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: soft_delete_post(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.soft_delete_post(post_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$-- used by app --
BEGIN
    UPDATE public.posts 
    SET deleted_at = NOW() 
    WHERE id = post_id;
END;$$;


--
-- Name: soft_delete_user_posts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.soft_delete_user_posts() RETURNS integer
    LANGUAGE plpgsql
    AS $$-- used by delete_current_user --
DECLARE
  current_user_id uuid;
  posts_deleted INTEGER;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Nessun utente autenticato';
  END IF;

  -- Verifica che l'utente esista
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = current_user_id) THEN
    RAISE EXCEPTION 'Profilo utente non trovato';
  END IF;

  UPDATE public.posts 
  SET deleted_at = NOW() 
  WHERE author_id = current_user_id 
    AND deleted_at IS NULL;
    
  GET DIAGNOSTICS posts_deleted = ROW_COUNT;
  
  RAISE NOTICE 'Soft deleted % posts for user %', posts_deleted, current_user_id;
  
  RETURN posts_deleted;
END;$$;


--
-- Name: soft_delete_user_posts(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.soft_delete_user_posts(user_uuid uuid) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    posts_affected INTEGER;
BEGIN
    -- Soft delete di tutti i post dell'utente che non sono già cancellati
    UPDATE public.posts 
    SET deleted_at = NOW() 
    WHERE author_id = user_uuid 
      AND deleted_at IS NULL;
    
    -- Ottieni il numero di post modificati
    GET DIAGNOSTICS posts_affected = ROW_COUNT;
    
    -- Log dell'operazione
    RAISE NOTICE 'Soft deleted % posts for user %', posts_affected, user_uuid;
    
    RETURN posts_affected;
END;
$$;


--
-- Name: trigger_soft_delete_user_posts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_soft_delete_user_posts() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Esegui soft delete dei post prima che l'utente venga eliminato
    PERFORM soft_delete_user_posts(OLD.id);
    
    RETURN OLD;
END;
$$;


--
-- Name: update_posts_children_on_parent_deleted_at_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_posts_children_on_parent_deleted_at_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verifica se deleted_at è stato modificato (da NULL a valore o viceversa)
    IF (OLD.deleted_at IS DISTINCT FROM NEW.deleted_at) THEN
        -- Aggiorna updated_at di tutti i post figli diretti
        UPDATE posts
        SET updated_at = NOW()
        WHERE parent_id = NEW.id;        
    END IF;
    
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_config (
    key text NOT NULL,
    value text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: calendar_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    post_id uuid NOT NULL,
    calendar_date date NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    connection_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: invite_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invite_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    creator_id uuid NOT NULL,
    used_by_id uuid,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    used_at timestamp with time zone
);


--
-- Name: post_exclusions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_exclusions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    post_id uuid NOT NULL,
    excluded_user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: post_media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_media (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    post_id uuid NOT NULL,
    media_type text NOT NULL,
    media_url text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT valid_sort_order CHECK ((sort_order >= 0))
);


--
-- Name: post_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_reactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    post_id uuid NOT NULL,
    user_id uuid NOT NULL,
    reaction text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: post_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    post_id uuid NOT NULL,
    reported_by uuid NOT NULL,
    reason text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: post_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    post_id uuid NOT NULL,
    tagged_user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    author_id uuid,
    content_date date NOT NULL,
    description text,
    status public.post_status DEFAULT 'draft'::public.post_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    content_type public.content_type NOT NULL,
    thumbnail_url text NOT NULL,
    thumbnail_width integer NOT NULL,
    thumbnail_height integer NOT NULL,
    deleted_at timestamp with time zone,
    parent_id uuid,
    published_at timestamp with time zone,
    published_timezone text DEFAULT 'UTC'::text NOT NULL,
    CONSTRAINT description_length CHECK (((description IS NULL) OR (char_length(description) <= 500)))
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    username text NOT NULL,
    biography text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT bio_length CHECK (((biography IS NULL) OR (char_length(biography) <= 200))),
    CONSTRAINT username_length CHECK ((char_length(username) <= 30))
);


--
-- Name: app_config app_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_config
    ADD CONSTRAINT app_config_pkey PRIMARY KEY (key);


--
-- Name: calendar_posts calendar_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_posts
    ADD CONSTRAINT calendar_posts_pkey PRIMARY KEY (id);


--
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: invite_codes invite_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_codes
    ADD CONSTRAINT invite_codes_pkey PRIMARY KEY (id);


--
-- Name: post_exclusions post_exclusions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_exclusions
    ADD CONSTRAINT post_exclusions_pkey PRIMARY KEY (id);


--
-- Name: post_media post_media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_media
    ADD CONSTRAINT post_media_pkey PRIMARY KEY (id);


--
-- Name: post_media post_media_unique_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_media
    ADD CONSTRAINT post_media_unique_type UNIQUE (post_id, media_type);


--
-- Name: post_tags post_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_tags
    ADD CONSTRAINT post_tags_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: calendar_posts_unique_date_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX calendar_posts_unique_date_per_user ON public.calendar_posts USING btree (user_id, calendar_date);


--
-- Name: connections_connection_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX connections_connection_id_idx ON public.connections USING btree (connection_id);


--
-- Name: connections_unique_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX connections_unique_direction ON public.connections USING btree (user_id, connection_id);


--
-- Name: connections_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX connections_user_id_idx ON public.connections USING btree (user_id);


--
-- Name: idx_calendar_posts_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_posts_post_id ON public.calendar_posts USING btree (post_id);


--
-- Name: idx_calendar_posts_user_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_posts_user_date ON public.calendar_posts USING btree (user_id, calendar_date DESC);


--
-- Name: idx_calendar_posts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_posts_user_id ON public.calendar_posts USING btree (user_id);


--
-- Name: idx_connections_connection_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_connection_user ON public.connections USING btree (connection_id, user_id);


--
-- Name: idx_connections_user_connection; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_connections_user_connection ON public.connections USING btree (user_id, connection_id);


--
-- Name: idx_post_exclusions_post_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_exclusions_post_user ON public.post_exclusions USING btree (post_id, excluded_user_id);


--
-- Name: idx_post_reactions_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reactions_post_id ON public.post_reactions USING btree (post_id);


--
-- Name: idx_post_reactions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reactions_user_id ON public.post_reactions USING btree (user_id);


--
-- Name: idx_post_reports_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_created_at ON public.post_reports USING btree (created_at DESC);


--
-- Name: idx_post_reports_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_post_id ON public.post_reports USING btree (post_id);


--
-- Name: idx_post_reports_post_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_post_user ON public.post_reports USING btree (post_id, reported_by);


--
-- Name: idx_post_reports_reported_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_reported_by ON public.post_reports USING btree (reported_by);


--
-- Name: idx_posts_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_active ON public.posts USING btree (author_id, created_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_posts_content_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_content_date ON public.posts USING btree (content_date);


--
-- Name: idx_posts_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_created_at ON public.posts USING btree (created_at DESC);


--
-- Name: idx_posts_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_deleted_at ON public.posts USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: idx_posts_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_parent_id ON public.posts USING btree (parent_id);


--
-- Name: idx_posts_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_status ON public.posts USING btree (status);


--
-- Name: idx_posts_status_content_date_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_status_content_date_created_at ON public.posts USING btree (status, content_date, created_at DESC);


--
-- Name: invite_codes_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invite_codes_code_key ON public.invite_codes USING btree (code);


--
-- Name: invite_codes_creator_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invite_codes_creator_id_idx ON public.invite_codes USING btree (creator_id);


--
-- Name: invite_codes_expires_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invite_codes_expires_at_idx ON public.invite_codes USING btree (expires_at);


--
-- Name: invite_codes_used_by_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invite_codes_used_by_id_idx ON public.invite_codes USING btree (used_by_id);


--
-- Name: post_exclusions_excluded_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX post_exclusions_excluded_user_id_idx ON public.post_exclusions USING btree (excluded_user_id);


--
-- Name: post_exclusions_post_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX post_exclusions_post_id_idx ON public.post_exclusions USING btree (post_id);


--
-- Name: post_exclusions_unique_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_exclusions_unique_pair ON public.post_exclusions USING btree (post_id, excluded_user_id);


--
-- Name: post_reactions_pkey; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_reactions_pkey ON public.post_reactions USING btree (id);


--
-- Name: post_reports_pkey; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_reports_pkey ON public.post_reports USING btree (id);


--
-- Name: post_tags_post_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX post_tags_post_id_idx ON public.post_tags USING btree (post_id);


--
-- Name: post_tags_tagged_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX post_tags_tagged_user_id_idx ON public.post_tags USING btree (tagged_user_id);


--
-- Name: post_tags_unique_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_tags_unique_pair ON public.post_tags USING btree (post_id, tagged_user_id);


--
-- Name: posts_author_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_author_id_idx ON public.posts USING btree (author_id);


--
-- Name: posts_content_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_content_date_idx ON public.posts USING btree (content_date DESC);


--
-- Name: posts_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_created_at_idx ON public.posts USING btree (created_at DESC);


--
-- Name: posts_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_status_idx ON public.posts USING btree (status);


--
-- Name: profiles_username_unique_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX profiles_username_unique_ci ON public.profiles USING btree (lower(username));


--
-- Name: unique_user_connection; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_user_connection ON public.connections USING btree (user_id, connection_id);


--
-- Name: unique_user_post_reaction; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_user_post_reaction ON public.post_reactions USING btree (post_id, user_id);


--
-- Name: unique_user_post_report; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_user_post_report ON public.post_reports USING btree (post_id, reported_by);


--
-- Name: post_reports on_report_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_report_created AFTER INSERT ON public.post_reports FOR EACH ROW EXECUTE FUNCTION public.send_email_on_new_report();


--
-- Name: posts set_published_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_published_at BEFORE INSERT OR UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.set_published_at_from_created();


--
-- Name: invite_codes trg_check_invite_limit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_check_invite_limit BEFORE INSERT ON public.invite_codes FOR EACH ROW EXECUTE FUNCTION public.check_invite_codes_limit();


--
-- Name: invite_codes trg_invite_codes_used_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_invite_codes_used_at BEFORE UPDATE ON public.invite_codes FOR EACH ROW EXECUTE FUNCTION public.set_invite_used_at();


--
-- Name: posts trg_posts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_posts_updated_at BEFORE UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: profiles trg_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: posts trg_remove_deleted_post_from_calendar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_remove_deleted_post_from_calendar AFTER UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.remove_deleted_post_from_calendar();


--
-- Name: posts trigger_posts_update_children_on_deleted_at_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_posts_update_children_on_deleted_at_change AFTER UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.update_posts_children_on_parent_deleted_at_change();


--
-- Name: post_reactions trigger_update_post_reactions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_post_reactions_updated_at BEFORE UPDATE ON public.post_reactions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: calendar_posts calendar_posts_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_posts
    ADD CONSTRAINT calendar_posts_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: calendar_posts calendar_posts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_posts
    ADD CONSTRAINT calendar_posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: invite_codes fk_invite_codes_creator_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite_codes
    ADD CONSTRAINT fk_invite_codes_creator_id FOREIGN KEY (creator_id) REFERENCES public.profiles(id);


--
-- Name: post_reactions post_reactions_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_reactions
    ADD CONSTRAINT post_reactions_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: posts posts_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: posts posts_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.posts(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: invite_codes Anyone can view valid codes for joining; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view valid codes for joining" ON public.invite_codes FOR SELECT USING (((used_by_id IS NULL) AND (expires_at > now())));


--
-- Name: post_reports Authenticated users can report posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can report posts" ON public.post_reports FOR INSERT WITH CHECK ((auth.uid() = reported_by));


--
-- Name: post_exclusions Authors can delete post exclusions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authors can delete post exclusions" ON public.post_exclusions FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.posts p
  WHERE ((p.id = post_exclusions.post_id) AND (p.author_id = auth.uid())))));


--
-- Name: post_tags Authors can manage post tags; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authors can manage post tags" ON public.post_tags USING ((post_id IN ( SELECT posts.id
   FROM public.posts
  WHERE (posts.author_id = auth.uid()))));


--
-- Name: posts Authors can manage their own posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authors can manage their own posts" ON public.posts USING ((auth.uid() = author_id)) WITH CHECK ((auth.uid() = author_id));


--
-- Name: post_exclusions Authors can modify post exclusions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authors can modify post exclusions" ON public.post_exclusions FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.posts p
  WHERE ((p.id = post_exclusions.post_id) AND (p.author_id = auth.uid())))));


--
-- Name: post_exclusions Authors can update post exclusions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authors can update post exclusions" ON public.post_exclusions FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.posts p
  WHERE ((p.id = post_exclusions.post_id) AND (p.author_id = auth.uid())))));


--
-- Name: post_reactions Chiunque può leggere le reactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chiunque può leggere le reactions" ON public.post_reactions FOR SELECT TO authenticated, anon USING (true);


--
-- Name: calendar_posts Circle members can view calendar posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Circle members can view calendar posts" ON public.calendar_posts FOR SELECT TO authenticated USING ((user_id IN ( SELECT connections.connection_id
   FROM public.connections
  WHERE (connections.user_id = auth.uid())
UNION
 SELECT connections.user_id
   FROM public.connections
  WHERE (connections.connection_id = auth.uid()))));


--
-- Name: post_media Media accessibili tramite post; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Media accessibili tramite post" ON public.post_media FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.posts p
  WHERE ((p.id = post_media.post_id) AND ((p.status = 'published'::public.post_status) OR (p.author_id = auth.uid()))))));


--
-- Name: post_reactions Only connections can react to posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only connections can react to posts" ON public.post_reactions FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.posts p
     LEFT JOIN public.connections c ON ((((c.user_id = auth.uid()) AND (c.connection_id = p.author_id)) OR ((c.connection_id = auth.uid()) AND (c.user_id = p.author_id)))))
  WHERE ((p.id = post_reactions.post_id) AND ((c.user_id IS NOT NULL) OR (p.author_id = auth.uid()))))));


--
-- Name: app_config Only security definer functions can read config; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only security definer functions can read config" ON public.app_config FOR SELECT USING (true);


--
-- Name: profiles Public profiles are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);


--
-- Name: calendar_posts Users can add own posts to calendar; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can add own posts to calendar" ON public.calendar_posts FOR INSERT TO authenticated WITH CHECK (((auth.uid() = user_id) AND (post_id IN ( SELECT posts.id
   FROM public.posts
  WHERE (posts.author_id = auth.uid())))));


--
-- Name: connections Users can create connections; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create connections" ON public.connections FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: invite_codes Users can create invite codes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create invite codes" ON public.invite_codes FOR INSERT WITH CHECK ((auth.uid() = creator_id));


--
-- Name: profiles Users can delete own account; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own account" ON public.profiles FOR DELETE USING ((auth.uid() = id));


--
-- Name: post_exclusions Users can hide posts for themselves; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can hide posts for themselves" ON public.post_exclusions FOR INSERT WITH CHECK ((excluded_user_id = auth.uid()));


--
-- Name: profiles Users can insert own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: profiles Users can read own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own profile" ON public.profiles FOR SELECT USING ((auth.uid() = id));


--
-- Name: calendar_posts Users can remove own calendar posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can remove own calendar posts" ON public.calendar_posts FOR DELETE TO authenticated USING ((auth.uid() = user_id));


--
-- Name: invite_codes Users can update own invite codes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own invite codes" ON public.invite_codes FOR UPDATE USING ((auth.uid() = creator_id));


--
-- Name: profiles Users can update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));


--
-- Name: calendar_posts Users can view own calendar posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own calendar posts" ON public.calendar_posts FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: invite_codes Users can view own invite codes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own invite codes" ON public.invite_codes FOR SELECT USING ((auth.uid() = creator_id));


--
-- Name: post_exclusions Users can view post exclusions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view post exclusions" ON public.post_exclusions FOR SELECT USING (true);


--
-- Name: posts Users can view published posts in their circle; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view published posts in their circle" ON public.posts FOR SELECT TO authenticated USING (((status = 'published'::public.post_status) AND ((author_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.connections c
  WHERE (((c.user_id = auth.uid()) AND (c.connection_id = posts.author_id)) OR ((c.connection_id = auth.uid()) AND (c.user_id = posts.author_id)))))) AND (NOT (EXISTS ( SELECT 1
   FROM public.post_exclusions pe
  WHERE ((pe.post_id = posts.id) AND (pe.excluded_user_id = auth.uid())))))));


--
-- Name: post_tags Users can view tags in visible published posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view tags in visible published posts" ON public.post_tags FOR SELECT USING ((post_id IN ( SELECT posts.id
   FROM public.posts
  WHERE ((posts.status = 'published'::public.post_status) AND ((posts.author_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.connections c
          WHERE (((c.user_id = auth.uid()) AND (c.connection_id = posts.author_id)) OR ((c.connection_id = auth.uid()) AND (c.user_id = posts.author_id)))))) AND (NOT (EXISTS ( SELECT 1
           FROM public.post_exclusions pe
          WHERE ((pe.post_id = posts.id) AND (pe.excluded_user_id = auth.uid())))))))));


--
-- Name: connections Users can view their connections; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their connections" ON public.connections FOR SELECT USING (((auth.uid() = user_id) OR (auth.uid() = connection_id)));


--
-- Name: post_reports Users can view their own reports; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own reports" ON public.post_reports FOR SELECT TO authenticated USING ((auth.uid() = reported_by));


--
-- Name: post_reactions Utenti possono aggiornare le proprie reactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Utenti possono aggiornare le proprie reactions" ON public.post_reactions FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: post_reactions Utenti possono eliminare le proprie reactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Utenti possono eliminare le proprie reactions" ON public.post_reactions FOR DELETE TO authenticated USING ((auth.uid() = user_id));


--
-- Name: post_media Utenti possono gestire media dei propri post; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Utenti possono gestire media dei propri post" ON public.post_media USING ((EXISTS ( SELECT 1
   FROM public.posts p
  WHERE ((p.id = post_media.post_id) AND (p.author_id = auth.uid())))));


--
-- Name: app_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

--
-- Name: calendar_posts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.calendar_posts ENABLE ROW LEVEL SECURITY;

--
-- Name: connections; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;

--
-- Name: invite_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: post_exclusions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.post_exclusions ENABLE ROW LEVEL SECURITY;

--
-- Name: post_media; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.post_media ENABLE ROW LEVEL SECURITY;

--
-- Name: post_reactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;

--
-- Name: post_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.post_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: post_tags; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.post_tags ENABLE ROW LEVEL SECURITY;

--
-- Name: posts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;


--
-- PostgreSQL database dump complete
--

