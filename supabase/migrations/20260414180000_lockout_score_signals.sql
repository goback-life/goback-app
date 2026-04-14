-- ============================================================================
-- LOCKOUT SCORE SIGNALS MIGRATION
-- ============================================================================
-- Adds raw signal columns to lockout_sessions for score debugging/tuning.
-- Updates update_lockout_score() RPC to accept and persist new fields.
-- ============================================================================

-- 1. Add columns
ALTER TABLE lockout_sessions
ADD COLUMN IF NOT EXISTS battery_was_charging BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS step_count SMALLINT DEFAULT NULL;

-- 2. Update RPC to accept new signal params
CREATE OR REPLACE FUNCTION update_lockout_score(
  p_session_id UUID,
  p_score INT,
  p_battery_was_charging BOOLEAN DEFAULT NULL,
  p_step_count INT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
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

  UPDATE lockout_sessions
  SET goback_score = LEAST(100, GREATEST(0, p_score)),
      battery_was_charging = p_battery_was_charging,
      step_count = CASE WHEN p_step_count IS NOT NULL
                        THEN LEAST(32767, GREATEST(0, p_step_count))
                        ELSE NULL END
  WHERE id = p_session_id;

  RETURN json_build_object('success', true);
END;
$$;
