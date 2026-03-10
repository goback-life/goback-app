-- ============================================================================
-- MIGRATION 014: Push Notification Queue
-- ============================================================================
-- Creates a queue table for push-worthy events, RPCs for token lookup,
-- modifies join_lockout_session to enqueue events, and adds triggers for
-- lockout_sessions INSERT and connection_requests INSERT.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. push_notification_queue table
-- No RLS — accessed only by SECURITY DEFINER functions + edge function
-- via service role.
-- ----------------------------------------------------------------------------
CREATE TABLE push_notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX idx_pnq_unprocessed
  ON push_notification_queue (created_at)
  WHERE processed_at IS NULL;

-- ----------------------------------------------------------------------------
-- 2. get_user_device_tokens(p_user_id)
-- Returns device tokens for a single user. Used for lockout_joined → owner
-- and connection_request → receiver.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_device_tokens(
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
  WHERE dt.user_id = p_user_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. get_friend_device_tokens_for_user(p_user_id)
-- Returns device tokens for a user's friends who are NOT currently locked out.
-- Used for friend_joins_lockout event (event 3).
-- Same logic as get_friend_device_tokens_for_lockout but named for the
-- "joiner's friends" use case.
-- ----------------------------------------------------------------------------
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
        AND ls.ends_at > NOW()
        AND ls.post_id IS NULL
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Modify join_lockout_session — add 2 queue inserts
-- After existing upsert_notification call, enqueue:
--   a) lockout_joined  (owner gets push)
--   b) friend_joins_lockout (joiner's friends get push)
-- ----------------------------------------------------------------------------
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

  -- In-app notification to owner
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  -- Push: notify owner that someone joined their lockout (event 1)
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('lockout_joined', jsonb_build_object(
    'owner_id', v_lockout.user_id,
    'joiner_id', v_user_id,
    'lockout_id', p_lockout_id
  ));

  -- Push: notify joiner's friends (event 3 — push only, no in-app)
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('friend_joins_lockout', jsonb_build_object(
    'joiner_id', v_user_id,
    'owner_id', v_lockout.user_id,
    'lockout_id', p_lockout_id
  ));

  RETURN json_build_object('success', true, 'message', 'Joined lockout');
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. Trigger on lockout_sessions INSERT → enqueue lockout_started
-- Only enqueues if lockout > 30 min remaining (joinable).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_enqueue_lockout_started()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only enqueue if > 30 min remaining (joinable lockout)
  IF NEW.ends_at > NOW() + INTERVAL '30 minutes' THEN
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('lockout_started', jsonb_build_object(
      'user_id', NEW.user_id,
      'lockout_id', NEW.id
    ));
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enqueue_lockout_started
  AFTER INSERT ON lockout_sessions
  FOR EACH ROW EXECUTE FUNCTION trigger_enqueue_lockout_started();

-- ----------------------------------------------------------------------------
-- 6. Trigger on connection_requests INSERT → enqueue connection_request
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_enqueue_connection_request()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('connection_request', jsonb_build_object(
    'sender_id', NEW.sender_id,
    'receiver_id', NEW.receiver_id,
    'request_id', NEW.id
  ));

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enqueue_connection_request
  AFTER INSERT ON connection_requests
  FOR EACH ROW EXECUTE FUNCTION trigger_enqueue_connection_request();
