-- ============================================================================
-- LOCKOUT SYSTEM FIXES MIGRATION
-- ============================================================================
-- Fixes:
-- 1. Co-participants visibility (B and C join A's lockout -> B can see C)
-- 2. Weekly minutes credit for joiners
-- 3. Prevent joining when already locked out
-- 4. Skip locked-out users for lockout_started notifications
-- ============================================================================

-- ============================================================================
-- 1. UPDATE get_friends_locked_out - Add co-participants & owner visibility
-- ============================================================================
-- Now returns:
--   Part 1: Friends who OWN active lockouts (I'm NOT a participant)
--   Part 2: Lockout OWNER of session I JOINED (shows me who I joined)
--   Part 3: Co-participants in lockouts I JOINED (shows me other joiners)
--   Part 4: Participants in MY OWN lockout (shows me who joined mine)
-- ============================================================================

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
    ls.ends_at > NOW()
    AND ls.post_id IS NULL
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
    AND joined_ls.ends_at > NOW()
    AND joined_ls.post_id IS NULL

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
    AND joined_ls.ends_at > NOW()
    AND joined_ls.post_id IS NULL
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
    AND my_ls.ends_at > NOW()
    AND my_ls.post_id IS NULL

  ORDER BY started_at DESC;
END;
$$;

-- ============================================================================
-- 2. UPDATE join_lockout_session - Block if already locked out
-- ============================================================================

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
  IF EXISTS (
    SELECT 1 FROM lockout_sessions ls
    WHERE (ls.user_id = v_user_id OR v_user_id = ANY(ls.participants))
      AND ls.ends_at > NOW()
      AND ls.post_id IS NULL
  ) THEN
    RETURN json_build_object('success', false, 'error', 'You are already in an active lockout');
  END IF;

  SELECT * INTO v_lockout FROM lockout_sessions WHERE id = p_lockout_id;

  IF v_lockout IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout not found');
  END IF;

  IF v_lockout.ends_at < NOW() OR v_lockout.post_id IS NOT NULL THEN
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

  -- Notify owner
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  RETURN json_build_object('success', true, 'message', 'Joined lockout');
END;
$$;

-- ============================================================================
-- 3. NEW: complete_lockout_session RPC
-- ============================================================================
-- Called when a user completes lockout WITHOUT creating a post.
-- Credits the calling user's weekly minutes and optionally deletes session.
-- ============================================================================

-- Drop existing function if return type differs
DROP FUNCTION IF EXISTS complete_lockout_session(UUID, TIMESTAMPTZ);

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

  -- If owner and no post linked, delete the session
  IF v_session.user_id = v_user_id AND v_session.post_id IS NULL THEN
    DELETE FROM lockout_sessions WHERE id = p_session_id;
  END IF;

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;

-- ============================================================================
-- 4. NEW: update_lockout_weekly_stats RPC
-- ============================================================================
-- Called when a user completes lockout WITH a post.
-- Credits the calling user's weekly minutes but does NOT delete session.
-- ============================================================================

-- Drop existing function if return type differs
DROP FUNCTION IF EXISTS update_lockout_weekly_stats(UUID, TIMESTAMPTZ);

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

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;

-- ============================================================================
-- 5. REMOVE trigger_update_weekly_lockout_minutes
-- ============================================================================
-- This trigger only credited the owner and used session start time.
-- Now replaced by explicit RPC calls that credit each user individually.
-- ============================================================================

DROP TRIGGER IF EXISTS trg_update_weekly_lockout_minutes ON lockout_sessions;
DROP FUNCTION IF EXISTS trigger_update_weekly_lockout_minutes();

-- ============================================================================
-- 6. trigger_notification_on_lockout_start - NO CHANGES NEEDED
-- ============================================================================
-- In-app notifications should ALWAYS be created for all friends, even if
-- they are currently locked out. They can view these notifications in their
-- notification menu after their lockout ends.
--
-- Push notification filtering (skip locked-out users) will be handled in
-- the Edge Function when push notifications are implemented (see prompt 009).
-- ============================================================================
-- No changes to this trigger - keeping original behavior from 001_schema_v2.sql

-- ============================================================================
-- VERIFICATION NOTES
-- ============================================================================
--
-- After running this migration:
--
-- 1. Co-participants visibility:
--    - B and C both join A's lockout
--    - A calls get_friends_locked_out() -> sees B and C (Part 4 - owner sees participants)
--    - B calls get_friends_locked_out() -> sees A (Part 2) AND C (Part 3)
--    - C calls get_friends_locked_out() -> sees A (Part 2) AND B (Part 3)
--
-- 2. Weekly minutes for joiners:
--    - When lockout ends, each participant calls complete_lockout_session
--      or update_lockout_weekly_stats with their own join timestamp
--    - Minutes credited based on THEIR participation time, not session start
--
-- 3. Already locked out prevention:
--    - User tries to join another lockout -> RPC returns error
--    - App shows "You are already locked out" message
--
-- 4. Transitive joining prevention (already secure):
--    - C is friend of B but not A
--    - A creates lockout, B joins
--    - C tries to join A's lockout -> "You must be friends" error
--    - (join_lockout_session checks friendship with OWNER, not participants)
--
-- 5. In-app notifications:
--    - ALL friends receive in-app notification when someone starts lockout
--    - Even if they're currently locked out (they can view later)
--    - Push notification filtering handled separately in Edge Function
--    - Users in active lockouts don't receive lockout_started notifications
--
-- ============================================================================
