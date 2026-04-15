-- ============================================================================
-- MIGRATION 018: Lockout completed_at & Venue Lifecycle RPCs
-- ============================================================================
-- Adds explicit completion tracking to lockout_sessions so venue (open-ended)
-- and timed lockouts record exactly when the user finished, rather than
-- relying solely on ends_at.
--
-- Changes:
--   1.  ADD COLUMN completed_at to lockout_sessions
--   2.  New RPC: complete_venue_lockout (NFC tap-out)
--   3.  New RPC: complete_timed_lockout (timer expiry)
--   4.  Update complete_lockout_session (skip flow) — use completed_at
--   5.  Update update_lockout_weekly_stats (post/share flow) — use completed_at
--   6.  Update is_lockout_joinable — exclude completed sessions
--   7.  Update get_friends_locked_out — exclude completed sessions
--   8.  New RPC: leader_complete_venue_lockout — leader ends for all
--   9.  New RPC: leave_venue_lockout — joiner early exit
--  10.  Update enforce_venue_lockout_min_post_duration trigger
--  11.  pg_cron: auto-delete stale venue sessions after 10 days
--  12.  Partial index on completed_at IS NULL
-- ============================================================================

-- ============================================================================
-- 1. ADD COLUMN completed_at
-- ============================================================================
-- NULL = lockout still active. Set to NOW() when lockout actually ends.
ALTER TABLE lockout_sessions ADD COLUMN completed_at TIMESTAMPTZ DEFAULT NULL;

-- ============================================================================
-- 12. Partial index for active-lockout queries (created early so all
--     subsequent functions benefit from it immediately)
-- ============================================================================
CREATE INDEX idx_lockout_sessions_completed_at
  ON lockout_sessions (completed_at)
  WHERE completed_at IS NULL;

-- ============================================================================
-- 2. complete_venue_lockout — NFC tap-out
-- ============================================================================
-- Called when a user taps out of a venue lockout (NFC scan to exit).
-- Sets completed_at = NOW() on the session. Idempotent.
-- Returns the session row as JSON so client can compute duration.
CREATE OR REPLACE FUNCTION complete_venue_lockout(p_session_id UUID)
RETURNS JSON
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

  -- Only owner or participant may complete
  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  -- Idempotent: if already completed, return success without updating
  IF v_session.completed_at IS NOT NULL THEN
    RETURN json_build_object(
      'success', true,
      'already_completed', true,
      'session', row_to_json(v_session)
    );
  END IF;

  UPDATE lockout_sessions
  SET completed_at = NOW()
  WHERE id = p_session_id
  RETURNING * INTO v_session;

  RETURN json_build_object(
    'success', true,
    'already_completed', false,
    'session', row_to_json(v_session)
  );
END;
$$;

-- ============================================================================
-- 3. complete_timed_lockout — timer expiry
-- ============================================================================
-- Called when a timed lockout timer expires (client calls at 0:00).
-- Sets completed_at = NOW(). Idempotent.
CREATE OR REPLACE FUNCTION complete_timed_lockout(p_session_id UUID)
RETURNS JSON
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

  -- Only owner or participant may complete
  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  -- Idempotent: already completed
  IF v_session.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', true, 'already_completed', true);
  END IF;

  UPDATE lockout_sessions
  SET completed_at = NOW()
  WHERE id = p_session_id;

  RETURN json_build_object('success', true, 'already_completed', false);
END;
$$;

-- ============================================================================
-- 4. complete_lockout_session — skip flow (no post)
-- ============================================================================
-- Patched: uses COALESCE(completed_at, NOW()) for duration calc.
-- Sets completed_at as fallback if still NULL.
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
  v_end_time TIMESTAMPTZ;
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

  -- Fallback: set completed_at if not already set
  IF v_session.completed_at IS NULL THEN
    UPDATE lockout_sessions
    SET completed_at = NOW()
    WHERE id = p_session_id;
    -- Use NOW() for duration calc below
    v_end_time := NOW();
  ELSE
    v_end_time := v_session.completed_at;
  END IF;

  -- Use provided start time (joiner's join time) or session start time (owner)
  v_start_time := COALESCE(p_user_started_at, v_session.started_at);

  -- Duration: from user's start to completion time
  v_duration_minutes := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) / 60;

  -- Log completion BEFORE any deletion (includes action_text per migration 015)
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

-- ============================================================================
-- 5. update_lockout_weekly_stats — post/share flow
-- ============================================================================
-- Patched: same completed_at fallback and duration calc as above.
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
  v_end_time TIMESTAMPTZ;
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

  -- Fallback: set completed_at if not already set
  IF v_session.completed_at IS NULL THEN
    UPDATE lockout_sessions
    SET completed_at = NOW()
    WHERE id = p_session_id;
    v_end_time := NOW();
  ELSE
    v_end_time := v_session.completed_at;
  END IF;

  v_start_time := COALESCE(p_user_started_at, v_session.started_at);

  -- Duration: from user's start to completion time
  v_duration_minutes := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) / 60;

  -- Log completion (includes action_text per migration 015)
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

-- ============================================================================
-- 6. is_lockout_joinable — exclude completed sessions
-- ============================================================================
CREATE OR REPLACE FUNCTION is_lockout_joinable(
  p_lockout_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ends_at TIMESTAMPTZ;
  v_post_id UUID;
  v_completed_at TIMESTAMPTZ;
  v_is_open_ended BOOLEAN;
BEGIN
  SELECT ends_at, post_id, completed_at, is_open_ended
  INTO v_ends_at, v_post_id, v_completed_at, v_is_open_ended
  FROM lockout_sessions
  WHERE id = p_lockout_id;

  IF v_ends_at IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Not joinable if already completed (has post)
  IF v_post_id IS NOT NULL THEN
    RETURN FALSE;
  END IF;

  -- Not joinable if already completed (tap-out / timer expiry)
  IF v_completed_at IS NOT NULL THEN
    RETURN FALSE;
  END IF;

  -- Open-ended lockouts are always joinable while active (no time limit)
  IF v_is_open_ended THEN
    RETURN TRUE;
  END IF;

  -- Timed lockouts: joinable if > 30 minutes remaining
  RETURN v_ends_at > NOW() + INTERVAL '30 minutes';
END;
$$;

-- ============================================================================
-- 7. get_friends_locked_out — exclude completed sessions
-- ============================================================================
-- Added: AND ls.completed_at IS NULL in all four UNION parts.
-- Friends stop seeing a user as locked out immediately on tap-out.
CREATE OR REPLACE FUNCTION get_friends_locked_out() RETURNS TABLE (
  lockout_id UUID,
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  started_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  action_text TEXT,
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  location_name TEXT,
  participants UUID[]
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  RETURN QUERY

  -- Part 1: Friends who OWN active lockouts (I'm NOT a participant)
  SELECT
    ls.id AS lockout_id,
    ls.user_id,
    prof.username,
    prof.avatar_url,
    ls.started_at,
    ls.ends_at,
    ls.action_text,
    ls.location_lat,
    ls.location_lng,
    ls.location_name,
    ls.participants
  FROM lockout_sessions ls
  JOIN profiles prof ON ls.user_id = prof.id
  WHERE
    (ls.is_open_ended OR ls.ends_at > NOW())
    AND ls.post_id IS NULL
    AND ls.completed_at IS NULL
    AND NOT (v_user_id = ANY(ls.participants))
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
    )

  UNION

  -- Part 2: Lockout OWNERS of sessions I JOINED (shows me the owner)
  SELECT
    joined_ls.id AS lockout_id,
    joined_ls.user_id,
    owner_prof.username,
    owner_prof.avatar_url,
    joined_ls.started_at,
    joined_ls.ends_at,
    joined_ls.action_text,
    joined_ls.location_lat,
    joined_ls.location_lng,
    joined_ls.location_name,
    joined_ls.participants
  FROM lockout_sessions joined_ls
  JOIN profiles owner_prof ON joined_ls.user_id = owner_prof.id
  WHERE
    v_user_id = ANY(joined_ls.participants)
    AND (joined_ls.is_open_ended OR joined_ls.ends_at > NOW())
    AND joined_ls.post_id IS NULL
    AND joined_ls.completed_at IS NULL

  UNION

  -- Part 3: Co-participants in lockouts I JOINED (shows me other joiners)
  SELECT
    joined_ls.id AS lockout_id,
    co_participant AS user_id,
    prof.username,
    prof.avatar_url,
    joined_ls.started_at,
    joined_ls.ends_at,
    joined_ls.action_text,
    joined_ls.location_lat,
    joined_ls.location_lng,
    joined_ls.location_name,
    joined_ls.participants
  FROM lockout_sessions joined_ls
  CROSS JOIN LATERAL unnest(joined_ls.participants) AS co_participant
  JOIN profiles prof ON co_participant = prof.id
  WHERE
    v_user_id = ANY(joined_ls.participants)
    AND co_participant != v_user_id
    AND (joined_ls.is_open_ended OR joined_ls.ends_at > NOW())
    AND joined_ls.post_id IS NULL
    AND joined_ls.completed_at IS NULL
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = co_participant)
         OR (f.user_b_id = v_user_id AND f.user_a_id = co_participant)
    )

  UNION

  -- Part 4: Participants in MY OWN lockout (I'm the owner, show me who joined)
  SELECT
    my_ls.id AS lockout_id,
    participant AS user_id,
    prof.username,
    prof.avatar_url,
    my_ls.started_at,
    my_ls.ends_at,
    my_ls.action_text,
    my_ls.location_lat,
    my_ls.location_lng,
    my_ls.location_name,
    my_ls.participants
  FROM lockout_sessions my_ls
  CROSS JOIN LATERAL unnest(my_ls.participants) AS participant
  JOIN profiles prof ON participant = prof.id
  WHERE
    my_ls.user_id = v_user_id
    AND (my_ls.is_open_ended OR my_ls.ends_at > NOW())
    AND my_ls.post_id IS NULL
    AND my_ls.completed_at IS NULL

  ORDER BY started_at DESC;
END;
$$;

-- ============================================================================
-- 8. leader_complete_venue_lockout — leader ends for all participants
-- ============================================================================
-- Leader (session owner) ends the venue lockout and pushes notifications
-- to all participants so their clients know to stop the lockout UI.
CREATE OR REPLACE FUNCTION leader_complete_venue_lockout(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
  v_participant UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF v_session IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  -- Only the leader (session owner) can end for everyone
  IF v_session.user_id != v_user_id THEN
    RETURN json_build_object('success', false, 'error', 'Only the lockout leader can end for everyone');
  END IF;

  -- Idempotent: already completed
  IF v_session.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', true, 'already_completed', true);
  END IF;

  -- Set completed_at
  UPDATE lockout_sessions
  SET completed_at = NOW()
  WHERE id = p_session_id;

  -- Notify each participant via push notification queue
  IF v_session.participants IS NOT NULL THEN
    FOREACH v_participant IN ARRAY v_session.participants
    LOOP
      INSERT INTO push_notification_queue (event_type, payload)
      VALUES ('lockout_completed', jsonb_build_object(
        'lockout_id', p_session_id,
        'user_id', v_participant,
        'venue_name', COALESCE(v_session.location_name, '')
      ));
    END LOOP;
  END IF;

  RETURN json_build_object('success', true, 'already_completed', false);
END;
$$;

-- ============================================================================
-- 9. leave_venue_lockout — joiner early exit
-- ============================================================================
-- A participant removes themselves from the lockout, logs their stats,
-- and credits their weekly minutes. Does NOT affect other participants
-- or the session itself.
CREATE OR REPLACE FUNCTION leave_venue_lockout(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
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

  -- Must be a participant (not the owner — owners use leader_complete or complete_lockout_session)
  IF NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'You are not a participant in this lockout');
  END IF;

  -- Remove caller from participants array
  UPDATE lockout_sessions
  SET participants = array_remove(participants, v_user_id)
  WHERE id = p_session_id;

  -- Calculate duration from session start to now (joiners don't have a separate join timestamp
  -- stored in the DB; p_user_started_at is tracked client-side and passed to complete/stats RPCs.
  -- For leave, we use session started_at as conservative lower bound — the joiner joined after
  -- session start so actual time is <= this. This slightly over-credits but is safe.)
  v_duration_minutes := EXTRACT(EPOCH FROM (NOW() - v_session.started_at)) / 60;

  -- Log the joiner's stats
  INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score, action_text)
  VALUES (
    v_user_id,
    (v_session.started_at AT TIME ZONE 'UTC')::date,
    GREATEST(0, v_duration_minutes),
    v_session.goback_score,
    v_session.action_text
  );

  -- Credit joiner's weekly minutes
  UPDATE profiles
  SET weekly_lockout_minutes = weekly_lockout_minutes + GREATEST(0, v_duration_minutes)
  WHERE id = v_user_id;

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;

-- ============================================================================
-- 10. Update enforce_venue_lockout_min_post_duration trigger
-- ============================================================================
-- Now uses completed_at instead of NOW() for the 10-minute check.
-- If completed_at is NULL (session still active), falls back to NOW().
CREATE OR REPLACE FUNCTION enforce_venue_lockout_min_post_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_session lockout_sessions%ROWTYPE;
BEGIN
  IF NEW.lockout_id IS NOT NULL THEN
    SELECT * INTO v_session FROM lockout_sessions WHERE id = NEW.lockout_id;
    IF FOUND AND v_session.is_open_ended THEN
      IF v_session.completed_at IS NOT NULL THEN
        -- Session is completed: check actual duration
        IF v_session.completed_at - v_session.started_at < INTERVAL '10 minutes' THEN
          RAISE EXCEPTION 'Venue lockouts must last at least 10 minutes before posting';
        END IF;
      ELSE
        -- Session still active: check elapsed time
        IF v_session.started_at IS NOT NULL
           AND NOW() - v_session.started_at < INTERVAL '10 minutes' THEN
          RAISE EXCEPTION 'Venue lockouts must last at least 10 minutes before posting';
        END IF;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 11. pg_cron: auto-delete stale venue sessions after 10 days
-- ============================================================================
-- Open-ended sessions that were never completed (user forgot to tap out,
-- app crashed, etc.) are cleaned up daily.
SELECT cron.schedule(
  'cleanup-stale-venue-lockouts',
  '0 4 * * *',
  $$DELETE FROM public.lockout_sessions WHERE is_open_ended = true AND completed_at IS NULL AND started_at < NOW() - INTERVAL '10 days'$$
);

-- ============================================================================
-- Also update join_lockout_session to recognize completed sessions
-- ============================================================================
-- Patched: adds completed_at IS NULL checks so users cannot join completed
-- sessions and the "already in active lockout" check excludes completed ones.
CREATE OR REPLACE FUNCTION join_lockout_session(p_lockout_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_lockout RECORD;
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

  -- Check friendship with OWNER (prevents transitive joining)
  IF NOT EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = v_user_id AND f.user_b_id = v_lockout.user_id)
       OR (f.user_b_id = v_user_id AND f.user_a_id = v_lockout.user_id)
  ) THEN
    RETURN json_build_object('success', false, 'error', 'You must be friends to join a lockout');
  END IF;

  -- Check if already joined
  IF v_user_id = ANY(v_lockout.participants) THEN
    RETURN json_build_object('success', true, 'message', 'Already joined this lockout');
  END IF;

  -- Add to participants
  UPDATE lockout_sessions
  SET participants = array_append(participants, v_user_id)
  WHERE id = p_lockout_id;

  -- In-app notification to owner
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  -- Push: notify owner that someone joined their lockout
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('lockout_joined', jsonb_build_object(
    'owner_id', v_lockout.user_id,
    'joiner_id', v_user_id,
    'lockout_id', p_lockout_id
  ));

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
-- Also update push-notification device token helpers to respect completed_at
-- ============================================================================
-- get_friend_device_tokens_for_user: exclude friends in completed lockouts
-- from the "currently locked out" filter (they should receive push notifications).
CREATE OR REPLACE FUNCTION get_friend_device_tokens_for_user(
  p_user_id UUID
) RETURNS TABLE (
  user_id UUID,
  token TEXT,
  platform TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT dt.user_id, dt.token, dt.platform
  FROM device_tokens dt
  WHERE
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = p_user_id AND f.user_b_id = dt.user_id)
         OR (f.user_b_id = p_user_id AND f.user_a_id = dt.user_id)
    )
    AND NOT EXISTS (
      SELECT 1 FROM lockout_sessions ls
      WHERE ls.user_id = dt.user_id
        AND (ls.is_open_ended OR ls.ends_at > NOW())
        AND ls.post_id IS NULL
        AND ls.completed_at IS NULL
    );
END;
$$;

-- ============================================================================
-- VERIFICATION NOTES
-- ============================================================================
--
-- After running this migration:
--
-- 1. completed_at column:
--    - All existing sessions get completed_at = NULL (still active or already
--      processed — the old ends_at logic continues to work as fallback)
--
-- 2. Venue lockout lifecycle:
--    - User taps NFC to start -> session created with is_open_ended=true
--    - User taps NFC to exit  -> client calls complete_venue_lockout
--    - Leader ends for all    -> client calls leader_complete_venue_lockout
--    - Joiner leaves early    -> client calls leave_venue_lockout
--
-- 3. Timed lockout lifecycle:
--    - User creates timed lockout -> session with ends_at set
--    - Timer hits 0:00           -> client calls complete_timed_lockout
--    - User skips / posts        -> complete_lockout_session / update_lockout_weekly_stats
--
-- 4. Duration calculation change:
--    - Old: LEAST(ends_at, NOW()) - started_at
--    - New: COALESCE(completed_at, NOW()) - COALESCE(p_user_started_at, started_at)
--    - Venue lockouts get accurate duration (tap-in to tap-out)
--    - Timed lockouts that complete early get accurate duration
--
-- 5. Stale session cleanup:
--    - pg_cron runs daily at 04:00 UTC
--    - Deletes open-ended sessions > 10 days old with no completion
--    - Prevents zombie venue lockouts from accumulating
--
-- 6. Index strategy:
--    - Partial index on completed_at WHERE NULL accelerates all active-session
--      queries (get_friends_locked_out, join checks, is_joinable)
--
-- ============================================================================
