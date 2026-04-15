-- ============================================================================
-- MIGRATION: Chain joining for lockout sessions
-- ============================================================================
-- Rewrites join_lockout_session and leave_venue_lockout to support chain
-- joining (friend-of-participant) and dual-write to lockout_participants.
--
-- Changes:
--   1. Rewrite join_lockout_session — chain joining via any participant
--   2. Rewrite leave_venue_lockout — dual-write to lockout_participants
--
-- Depends on: 20260415120000_lockout_participants.sql (lockout_participants table)
-- ============================================================================


-- ============================================================================
-- 1. REWRITE join_lockout_session — chain joining
-- ============================================================================
-- CHANGE from previous version:
--   - Instead of checking friendship with OWNER only, find a friend among ANY
--     current participant (owner or anyone in participants array).
--   - Record which friend was the link in joined_via.
--   - Set joined_via = NULL if the link is the session owner (direct friend).
--   - Dual-write: array_append on lockout_sessions.participants AND INSERT
--     INTO lockout_participants.
--   - Add push notification to joined_via user (chain_join event).
-- ============================================================================
CREATE OR REPLACE FUNCTION join_lockout_session(p_lockout_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_lockout RECORD;
  v_joined_via UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  -- Check if user is already in an active lockout (own or joined)
  -- Exclude completed sessions so user can join a new lockout after completing one
  IF EXISTS (
    SELECT 1 FROM lockout_sessions ls
    WHERE (ls.user_id = v_user_id OR v_user_id = ANY(ls.participants))
      AND (ls.is_open_ended OR ls.ends_at > NOW())
      AND ls.post_id IS NULL
      AND ls.completed_at IS NULL
  ) THEN
    RETURN json_build_object('success', false, 'error', 'You are already in an active lockout');
  END IF;

  SELECT * INTO v_lockout FROM lockout_sessions WHERE id = p_lockout_id;

  IF v_lockout IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout not found');
  END IF;

  -- Cannot join a completed lockout
  IF v_lockout.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  IF (NOT v_lockout.is_open_ended AND v_lockout.ends_at < NOW()) OR v_lockout.post_id IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  -- Check if already joined
  IF v_user_id = ANY(v_lockout.participants) THEN
    RETURN json_build_object('success', true, 'message', 'Already joined this lockout');
  END IF;

  -- Find a friend who is already in the lockout (owner or participant)
  SELECT friend_id INTO v_joined_via
  FROM (
    SELECT v_lockout.user_id AS friend_id
    UNION ALL
    SELECT unnest(v_lockout.participants) AS friend_id
  ) candidates
  WHERE EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = v_user_id AND f.user_b_id = candidates.friend_id)
       OR (f.user_b_id = v_user_id AND f.user_a_id = candidates.friend_id)
  )
  LIMIT 1;

  IF v_joined_via IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'You must be friends with someone in this lockout');
  END IF;

  -- Set joined_via to NULL if the link is the session owner (direct friend)
  IF v_joined_via = v_lockout.user_id THEN
    v_joined_via := NULL;
  END IF;

  -- Dual-write: add to participants array (backwards compat)
  UPDATE lockout_sessions
  SET participants = array_append(participants, v_user_id)
  WHERE id = p_lockout_id;

  -- Dual-write: insert into lockout_participants (normalised table)
  INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
  VALUES (p_lockout_id, v_user_id, v_joined_via, NOW())
  ON CONFLICT (session_id, user_id) DO NOTHING;

  -- In-app notification to owner
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  -- Push: notify owner that someone joined their lockout
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('lockout_joined', jsonb_build_object(
    'owner_id', v_lockout.user_id,
    'joiner_id', v_user_id,
    'lockout_id', p_lockout_id
  ));

  -- Push: notify the joined_via user about chain join (if not the owner)
  IF v_joined_via IS NOT NULL THEN
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('chain_join', jsonb_build_object(
      'joined_via_id', v_joined_via,
      'joiner_id', v_user_id,
      'owner_id', v_lockout.user_id,
      'lockout_id', p_lockout_id
    ));
  END IF;

  -- Push: notify joiner's friends
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('friend_joins_lockout', jsonb_build_object(
    'joiner_id', v_user_id,
    'owner_id', v_lockout.user_id,
    'lockout_id', p_lockout_id
  ));

  RETURN json_build_object('success', true, 'message', 'Joined lockout');
END;
$$;


-- ============================================================================
-- 2. REWRITE leave_venue_lockout — dual-write to lockout_participants
-- ============================================================================
-- CHANGE from previous version:
--   - Also UPDATE lockout_participants SET left_at = NOW() for the leaving user.
--   - Read goback_score from lockout_participants instead of lockout_sessions
--     when logging to lockout_completed_log.
-- ============================================================================
CREATE OR REPLACE FUNCTION leave_venue_lockout(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
  v_participant RECORD;
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

  -- Must be a participant (not the owner -- owners use leader_complete or complete_lockout_session)
  IF NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'You are not a participant in this lockout');
  END IF;

  -- Read participant row for goback_score and joined_at
  SELECT * INTO v_participant
  FROM lockout_participants
  WHERE session_id = p_session_id AND user_id = v_user_id;

  -- Remove caller from participants array (backwards compat)
  UPDATE lockout_sessions
  SET participants = array_remove(participants, v_user_id)
  WHERE id = p_session_id;

  -- Mark left_at in lockout_participants
  UPDATE lockout_participants
  SET left_at = NOW()
  WHERE session_id = p_session_id AND user_id = v_user_id;

  -- Calculate duration from session start to now (joiners don't have a separate join timestamp
  -- stored in the DB; p_user_started_at is tracked client-side and passed to complete/stats RPCs.
  -- For leave, we use session started_at as conservative lower bound -- the joiner joined after
  -- session start so actual time is <= this. This slightly over-credits but is safe.)
  v_duration_minutes := EXTRACT(EPOCH FROM (NOW() - v_session.started_at)) / 60;

  -- Log the joiner's stats (use goback_score from lockout_participants if available)
  INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score, action_text)
  VALUES (
    v_user_id,
    (v_session.started_at AT TIME ZONE 'UTC')::date,
    GREATEST(0, v_duration_minutes),
    COALESCE(v_participant.goback_score, v_session.goback_score),
    v_session.action_text
  );

  -- Credit joiner's weekly minutes
  UPDATE profiles
  SET weekly_lockout_minutes = weekly_lockout_minutes + GREATEST(0, v_duration_minutes)
  WHERE id = v_user_id;

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;
