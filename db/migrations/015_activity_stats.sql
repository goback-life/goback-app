-- ============================================================================
-- Migration 015: Activity Stats for Hobbies Bubble Cloud
-- ============================================================================
-- Adds action_text column to lockout_completed_log so the profile "Hobbies"
-- tab can aggregate lockout minutes per activity over the rolling 28-day
-- retention window.
--
-- Changes:
--   1. ALTER TABLE lockout_completed_log ADD COLUMN action_text
--   2. Patch complete_lockout_session to persist action_text in the log
--   3. Patch update_lockout_weekly_stats to persist action_text in the log
--   4. New RPC get_lockout_activity_stats — aggregates by action_text
-- ============================================================================

-- 1. Add column ---------------------------------------------------------------
ALTER TABLE lockout_completed_log ADD COLUMN action_text TEXT;

-- 2. Patch complete_lockout_session -------------------------------------------
CREATE OR REPLACE FUNCTION complete_lockout_session(
  p_session_id UUID,
  p_user_started_at TIMESTAMPTZ DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
  v_start_time TIMESTAMPTZ;
  v_duration_minutes INT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF v_session IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  v_start_time := COALESCE(p_user_started_at, v_session.started_at);
  v_duration_minutes := EXTRACT(EPOCH FROM (LEAST(v_session.ends_at, NOW()) - v_start_time)) / 60;

  -- Log completion BEFORE any deletion (now includes action_text)
  INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score, action_text)
  VALUES (
    v_user_id,
    (v_start_time AT TIME ZONE 'UTC')::date,
    GREATEST(0, v_duration_minutes),
    v_session.goback_score,
    v_session.action_text
  );

  -- Credit weekly minutes
  UPDATE profiles
  SET weekly_lockout_minutes = weekly_lockout_minutes + GREATEST(0, v_duration_minutes)
  WHERE id = v_user_id;

  -- Delete only when owner skipped AND no participants joined
  IF v_session.user_id = v_user_id AND v_session.post_id IS NULL
     AND COALESCE(array_length(v_session.participants, 1), 0) = 0 THEN
    DELETE FROM lockout_sessions WHERE id = p_session_id;
  END IF;

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;

-- 3. Patch update_lockout_weekly_stats ----------------------------------------
CREATE OR REPLACE FUNCTION update_lockout_weekly_stats(
  p_session_id UUID,
  p_user_started_at TIMESTAMPTZ DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
  v_start_time TIMESTAMPTZ;
  v_duration_minutes INT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF v_session IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  v_start_time := COALESCE(p_user_started_at, v_session.started_at);
  v_duration_minutes := EXTRACT(EPOCH FROM (LEAST(v_session.ends_at, NOW()) - v_start_time)) / 60;

  -- Log completion (now includes action_text)
  INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score, action_text)
  VALUES (
    v_user_id,
    (v_start_time AT TIME ZONE 'UTC')::date,
    GREATEST(0, v_duration_minutes),
    v_session.goback_score,
    v_session.action_text
  );

  -- Credit weekly minutes
  UPDATE profiles
  SET weekly_lockout_minutes = weekly_lockout_minutes + GREATEST(0, v_duration_minutes)
  WHERE id = v_user_id;

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;

-- 4. Activity stats RPC -------------------------------------------------------
CREATE OR REPLACE FUNCTION get_lockout_activity_stats(p_user_id UUID)
RETURNS TABLE(action_text TEXT, total_minutes INT, session_count INT)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
  v_cutoff DATE := (CURRENT_DATE - INTERVAL '27 days')::date;
BEGIN
  RETURN QUERY
  SELECT
    l.action_text,
    COALESCE(SUM(l.duration_minutes), 0)::int AS total_minutes,
    COUNT(*)::int AS session_count
  FROM lockout_completed_log l
  WHERE l.user_id = p_user_id
    AND l.session_date >= v_cutoff
    AND l.action_text IS NOT NULL
  GROUP BY l.action_text
  ORDER BY total_minutes DESC;
END;
$$;
