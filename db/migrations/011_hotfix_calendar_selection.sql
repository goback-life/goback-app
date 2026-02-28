-- Hotfix: Run in Supabase SQL Editor
-- Fix 1: Skip dates that already have a saved calendar post (one-per-day limit)
-- Fix 2: Never prompt for today's posts — only previous days

-- get_pending_selection_posts
CREATE OR REPLACE FUNCTION get_pending_selection_posts(
  p_date DATE DEFAULT NULL
) RETURNS TABLE (
  id UUID, author_id UUID, thumbnail_url TEXT,
  thumbnail_width INT, thumbnail_height INT, content_type TEXT,
  description TEXT, published_at TIMESTAMPTZ, published_timezone TEXT, lockout_id UUID
) LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID;
  v_target_date DATE;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User not authenticated'; END IF;

  IF p_date IS NOT NULL THEN
    v_target_date := p_date;
  ELSE
    -- Find most recent PREVIOUS date with unsaved lockout posts and no saved post
    SELECT DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC'))
    INTO v_target_date
    FROM posts p
    WHERE p.author_id = v_user_id
      AND p.calendar_saved_at IS NULL
      AND p.lockout_id IS NOT NULL
      AND p.published_at > NOW() - INTERVAL '72 hours'
      AND DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) < CURRENT_DATE
      AND NOT EXISTS (
        SELECT 1 FROM posts p2
        WHERE p2.author_id = v_user_id
          AND p2.calendar_saved_at IS NOT NULL
          AND DATE(p2.published_at AT TIME ZONE COALESCE(p2.published_timezone, 'UTC'))
            = DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC'))
      )
    ORDER BY p.published_at DESC LIMIT 1;

    IF v_target_date IS NULL THEN RETURN; END IF;
  END IF;

  RETURN QUERY
  SELECT p.id, p.author_id, p.thumbnail_url, p.thumbnail_width, p.thumbnail_height,
    p.content_type::TEXT, p.description, p.published_at, p.published_timezone, p.lockout_id
  FROM posts p
  WHERE p.author_id = v_user_id
    AND p.calendar_saved_at IS NULL
    AND p.lockout_id IS NOT NULL
    AND DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = v_target_date
    AND p.published_at > NOW() - INTERVAL '72 hours'
  ORDER BY p.published_at DESC;
END; $$;

-- has_pending_selection
CREATE OR REPLACE FUNCTION has_pending_selection(
  p_date DATE DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID;
  v_count INT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN RETURN FALSE; END IF;

  IF p_date IS NOT NULL THEN
    SELECT COUNT(*) INTO v_count
    FROM posts p
    WHERE p.author_id = v_user_id
      AND p.calendar_saved_at IS NULL
      AND p.lockout_id IS NOT NULL
      AND DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) = p_date
      AND p.published_at > NOW() - INTERVAL '72 hours'
      AND NOT EXISTS (
        SELECT 1 FROM posts p2
        WHERE p2.author_id = v_user_id
          AND p2.calendar_saved_at IS NOT NULL
          AND DATE(p2.published_at AT TIME ZONE COALESCE(p2.published_timezone, 'UTC')) = p_date
      );
  ELSE
    -- Only check previous days, not today
    SELECT COUNT(*) INTO v_count
    FROM posts p
    WHERE p.author_id = v_user_id
      AND p.calendar_saved_at IS NULL
      AND p.lockout_id IS NOT NULL
      AND p.published_at > NOW() - INTERVAL '72 hours'
      AND DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC')) < CURRENT_DATE
      AND NOT EXISTS (
        SELECT 1 FROM posts p2
        WHERE p2.author_id = v_user_id
          AND p2.calendar_saved_at IS NOT NULL
          AND DATE(p2.published_at AT TIME ZONE COALESCE(p2.published_timezone, 'UTC'))
            = DATE(p.published_at AT TIME ZONE COALESCE(p.published_timezone, 'UTC'))
      );
  END IF;

  RETURN v_count > 0;
END; $$;
