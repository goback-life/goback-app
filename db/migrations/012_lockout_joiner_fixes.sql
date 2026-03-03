-- ============================================================================
-- Migration 012: Lockout Joiner Fixes
-- ============================================================================
-- Fixes three issues that cause errors when a joiner posts after lockout ends:
-- 1. RLS gap: joiners can't SELECT expired sessions they participated in
-- 2. FK violation: owner skip deletes session while joiner still needs it
-- ============================================================================

-- 1. Allow participants to read sessions they joined (needed for auto-tagging)
CREATE POLICY "Participants can view joined lockouts"
  ON lockout_sessions FOR SELECT
  USING (auth.uid() = ANY(participants));

-- 2. Don't delete session on owner skip when participants exist
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

  -- Verify user is owner or participant
  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  -- Use provided start time (joiner's join time) or session start time (owner)
  v_start_time := COALESCE(p_user_started_at, v_session.started_at);

  -- Calculate duration (capped at actual end time or now if still active)
  v_duration_minutes := EXTRACT(EPOCH FROM (LEAST(v_session.ends_at, NOW()) - v_start_time)) / 60;

  -- Credit the calling user's weekly minutes
  UPDATE profiles
  SET weekly_lockout_minutes = weekly_lockout_minutes + GREATEST(0, v_duration_minutes)
  WHERE id = v_user_id;

  -- If owner and no post linked, delete ONLY when no participants joined
  IF v_session.user_id = v_user_id AND v_session.post_id IS NULL
     AND COALESCE(array_length(v_session.participants, 1), 0) = 0 THEN
    DELETE FROM lockout_sessions WHERE id = p_session_id;
  END IF;

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;
