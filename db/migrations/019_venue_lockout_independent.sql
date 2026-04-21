-- ============================================================================
-- MIGRATION 019: Venue Lockout Independent Sessions
-- ============================================================================
-- Changes venue lockouts from shared-session (participants[]) model to
-- independent per-user sessions linked by shared venue_tag_id.
--
-- Changes:
--   1. New RPC: get_venue_companions — friends at same venue with overlap
--   2. New RPC: notify_venue_departure — push notif when someone leaves
--   3. Modify leader_complete_venue_lockout — own session only + departure notif
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. get_venue_companions
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_venue_companions(p_session_id UUID)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  started_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_venue_tag_id TEXT;
  v_started_at TIMESTAMPTZ;
  v_completed_at TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();

  SELECT ls.venue_tag_id, ls.started_at, ls.completed_at
  INTO v_venue_tag_id, v_started_at, v_completed_at
  FROM lockout_sessions ls
  WHERE ls.id = p_session_id AND ls.user_id = v_user_id;

  IF v_venue_tag_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    ls.user_id,
    p.username,
    p.avatar_url,
    ls.started_at
  FROM lockout_sessions ls
  JOIN profiles p ON ls.user_id = p.id
  WHERE ls.venue_tag_id = v_venue_tag_id
    AND ls.id != p_session_id
    AND ls.is_open_ended = true
    AND ls.started_at < COALESCE(v_completed_at, NOW())
    AND COALESCE(ls.completed_at, NOW()) > v_started_at
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. notify_venue_departure
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_venue_departure(p_session_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_venue_tag_id TEXT;
  v_location_name TEXT;
  v_username TEXT;
  v_companion RECORD;
BEGIN
  v_user_id := auth.uid();

  SELECT ls.venue_tag_id, ls.location_name
  INTO v_venue_tag_id, v_location_name
  FROM lockout_sessions ls
  WHERE ls.id = p_session_id AND ls.user_id = v_user_id;

  IF v_venue_tag_id IS NULL THEN
    RETURN;
  END IF;

  SELECT p.username INTO v_username FROM profiles p WHERE p.id = v_user_id;

  FOR v_companion IN
    SELECT ls.user_id
    FROM lockout_sessions ls
    WHERE ls.venue_tag_id = v_venue_tag_id
      AND ls.id != p_session_id
      AND ls.is_open_ended = true
      AND ls.completed_at IS NULL
      AND EXISTS (
        SELECT 1 FROM friendships f
        WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
           OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
      )
  LOOP
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('venue_departure', jsonb_build_object(
      'user_id', v_companion.user_id,
      'departed_user_id', v_user_id,
      'departed_username', v_username,
      'venue_name', COALESCE(v_location_name, ''),
      'lockout_id', p_session_id
    ));
  END LOOP;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Modify leader_complete_venue_lockout — own session only
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION leader_complete_venue_lockout(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session lockout_sessions%ROWTYPE;
BEGIN
  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  IF v_session.user_id != auth.uid() THEN
    RETURN json_build_object('success', false, 'error', 'Not your session');
  END IF;

  IF v_session.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', true, 'already_completed', true);
  END IF;

  UPDATE lockout_sessions SET completed_at = NOW() WHERE id = p_session_id;

  -- Send departure notifications to friends at same venue
  PERFORM notify_venue_departure(p_session_id);

  RETURN json_build_object('success', true);
END;
$$;
