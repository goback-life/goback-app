-- ============================================================================
-- MIGRATION 010: Connection Requests
-- ============================================================================
-- Adds user search + connection request system alongside existing invite codes.
-- Delete-based lifecycle: only pending rows live in connection_requests.
-- Accept/deny/cancel/expire = DELETE. No status column.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: connection_requests (pending only)
-- ----------------------------------------------------------------------------
CREATE TABLE connection_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days',
  CONSTRAINT no_self_request CHECK (sender_id != receiver_id),
  CONSTRAINT unique_pending_pair UNIQUE (sender_id, receiver_id)
);

-- Fast lookup for receiver's incoming requests
CREATE INDEX idx_cr_receiver ON connection_requests (receiver_id);

-- Scalable username prefix search (B-tree on lower(username))
CREATE INDEX idx_profiles_username_lower ON profiles (lower(username));

-- ----------------------------------------------------------------------------
-- RLS policies
-- ----------------------------------------------------------------------------
ALTER TABLE connection_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY cr_select ON connection_requests FOR SELECT
  USING (auth.uid() IN (sender_id, receiver_id));

CREATE POLICY cr_insert ON connection_requests FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY cr_delete ON connection_requests FOR DELETE
  USING (auth.uid() IN (sender_id, receiver_id));

-- ----------------------------------------------------------------------------
-- RPC: search_users
-- Phone (starts with digit/+): exact match on profiles.phone_number
-- Username: prefix search on lower(username)
-- Excludes self; computes connection_status via EXISTS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_users(
  p_query TEXT,
  p_limit INT DEFAULT 20
) RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  connection_status TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID;
  v_is_phone BOOLEAN;
  v_normalized TEXT;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Detect phone vs username query
  v_is_phone := LEFT(TRIM(p_query), 1) ~ '[0-9+]';

  IF v_is_phone THEN
    -- Normalize: strip spaces/dashes
    v_normalized := regexp_replace(TRIM(p_query), '[\s\-]', '', 'g');

    RETURN QUERY
    SELECT
      p.id AS user_id,
      p.username,
      p.avatar_url,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM friendships f
          WHERE (f.user_a_id = LEAST(v_uid, p.id) AND f.user_b_id = GREATEST(v_uid, p.id))
        ) THEN 'connected'
        WHEN EXISTS (
          SELECT 1 FROM connection_requests cr
          WHERE cr.sender_id = v_uid AND cr.receiver_id = p.id AND cr.expires_at > NOW()
        ) THEN 'pending_outgoing'
        WHEN EXISTS (
          SELECT 1 FROM connection_requests cr
          WHERE cr.sender_id = p.id AND cr.receiver_id = v_uid AND cr.expires_at > NOW()
        ) THEN 'pending_incoming'
        ELSE 'none'
      END AS connection_status
    FROM profiles p
    WHERE p.phone_number = v_normalized
      AND p.id != v_uid
    LIMIT p_limit;
  ELSE
    RETURN QUERY
    SELECT
      p.id AS user_id,
      p.username,
      p.avatar_url,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM friendships f
          WHERE (f.user_a_id = LEAST(v_uid, p.id) AND f.user_b_id = GREATEST(v_uid, p.id))
        ) THEN 'connected'
        WHEN EXISTS (
          SELECT 1 FROM connection_requests cr
          WHERE cr.sender_id = v_uid AND cr.receiver_id = p.id AND cr.expires_at > NOW()
        ) THEN 'pending_outgoing'
        WHEN EXISTS (
          SELECT 1 FROM connection_requests cr
          WHERE cr.sender_id = p.id AND cr.receiver_id = v_uid AND cr.expires_at > NOW()
        ) THEN 'pending_incoming'
        ELSE 'none'
      END AS connection_status
    FROM profiles p
    WHERE lower(p.username) LIKE lower(TRIM(p_query)) || '%'
      AND p.id != v_uid
    ORDER BY p.username
    LIMIT p_limit;
  END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- RPC: send_connection_request
-- Guards: not self, not connected, no duplicate, both circles < 150
-- Mutual detection: auto-accept if reverse request exists
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION send_connection_request(
  p_receiver_id UUID
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID;
  v_user_a UUID;
  v_user_b UUID;
  v_my_circle INT;
  v_their_circle INT;
  v_reverse_id UUID;
  v_request_id UUID;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Guard: not self
  IF v_uid = p_receiver_id THEN
    RAISE EXCEPTION 'Cannot send request to yourself';
  END IF;

  -- Guard: not already connected
  v_user_a := LEAST(v_uid, p_receiver_id);
  v_user_b := GREATEST(v_uid, p_receiver_id);
  IF EXISTS (SELECT 1 FROM friendships WHERE user_a_id = v_user_a AND user_b_id = v_user_b) THEN
    RAISE EXCEPTION 'Already connected';
  END IF;

  -- Guard: no existing outgoing request
  IF EXISTS (
    SELECT 1 FROM connection_requests
    WHERE sender_id = v_uid AND receiver_id = p_receiver_id AND expires_at > NOW()
  ) THEN
    RAISE EXCEPTION 'Request already pending';
  END IF;

  -- Guard: circle sizes < 150
  SELECT COUNT(*) INTO v_my_circle FROM friendships
    WHERE user_a_id = v_uid OR user_b_id = v_uid;
  SELECT COUNT(*) INTO v_their_circle FROM friendships
    WHERE user_a_id = p_receiver_id OR user_b_id = p_receiver_id;

  IF v_my_circle >= 150 THEN
    RAISE EXCEPTION 'Your circle is full';
  END IF;
  IF v_their_circle >= 150 THEN
    RAISE EXCEPTION 'Their circle is full';
  END IF;

  -- Mutual detection: check if receiver already sent us a request
  SELECT id INTO v_reverse_id FROM connection_requests
    WHERE sender_id = p_receiver_id AND receiver_id = v_uid AND expires_at > NOW();

  IF v_reverse_id IS NOT NULL THEN
    -- Auto-accept: delete reverse request, create friendship, notify both
    DELETE FROM connection_requests WHERE id = v_reverse_id;
    INSERT INTO friendships (user_a_id, user_b_id) VALUES (v_user_a, v_user_b);
    PERFORM upsert_notification(v_uid, 'friend_joined', v_reverse_id, p_receiver_id);
    PERFORM upsert_notification(p_receiver_id, 'friend_joined', v_reverse_id, v_uid);
    RETURN 'auto_accepted';
  END IF;

  -- Normal: insert request + notify receiver
  INSERT INTO connection_requests (sender_id, receiver_id)
    VALUES (v_uid, p_receiver_id)
    RETURNING id INTO v_request_id;

  PERFORM upsert_notification(p_receiver_id, 'connection_request', v_request_id, v_uid);

  RETURN 'sent';
END;
$$;

-- ----------------------------------------------------------------------------
-- RPC: respond_to_connection_request
-- Accept: check circles < 150, create friendship, notify sender, delete request
-- Deny: delete request + associated notification
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION respond_to_connection_request(
  p_request_id UUID,
  p_accept BOOLEAN
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID;
  v_sender_id UUID;
  v_receiver_id UUID;
  v_expires_at TIMESTAMPTZ;
  v_user_a UUID;
  v_user_b UUID;
  v_my_circle INT;
  v_their_circle INT;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Fetch and verify request
  SELECT sender_id, receiver_id, expires_at
    INTO v_sender_id, v_receiver_id, v_expires_at
    FROM connection_requests WHERE id = p_request_id;

  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  IF v_receiver_id != v_uid THEN
    RAISE EXCEPTION 'Not authorized to respond to this request';
  END IF;

  IF v_expires_at < NOW() THEN
    DELETE FROM connection_requests WHERE id = p_request_id;
    RAISE EXCEPTION 'Request has expired';
  END IF;

  IF p_accept THEN
    -- Check circle sizes
    SELECT COUNT(*) INTO v_my_circle FROM friendships
      WHERE user_a_id = v_uid OR user_b_id = v_uid;
    SELECT COUNT(*) INTO v_their_circle FROM friendships
      WHERE user_a_id = v_sender_id OR user_b_id = v_sender_id;

    IF v_my_circle >= 150 THEN
      RAISE EXCEPTION 'Your circle is full';
    END IF;
    IF v_their_circle >= 150 THEN
      RAISE EXCEPTION 'Their circle is full';
    END IF;

    -- Create friendship (ordered UUIDs)
    v_user_a := LEAST(v_uid, v_sender_id);
    v_user_b := GREATEST(v_uid, v_sender_id);
    INSERT INTO friendships (user_a_id, user_b_id) VALUES (v_user_a, v_user_b);

    -- Notify sender
    PERFORM upsert_notification(v_sender_id, 'friend_joined', p_request_id, v_uid);
  END IF;

  -- Delete request (both accept and deny)
  DELETE FROM connection_requests WHERE id = p_request_id;

  -- Delete the connection_request notification
  DELETE FROM notifications
    WHERE user_id = v_uid AND type = 'connection_request' AND reference_id = p_request_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- RPC: get_outgoing_connection_requests
-- Returns pending outgoing requests with receiver profile info
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_outgoing_connection_requests() RETURNS TABLE (
  request_id UUID,
  receiver_id UUID,
  receiver_username TEXT,
  receiver_avatar_url TEXT,
  created_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    cr.id AS request_id,
    cr.receiver_id,
    p.username AS receiver_username,
    p.avatar_url AS receiver_avatar_url,
    cr.created_at,
    cr.expires_at
  FROM connection_requests cr
  JOIN profiles p ON cr.receiver_id = p.id
  WHERE cr.sender_id = v_uid
    AND cr.expires_at > NOW()
  ORDER BY cr.created_at DESC;
END;
$$;

-- ----------------------------------------------------------------------------
-- Update get_notification_feed to include connection_request type
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS get_notification_feed();

CREATE OR REPLACE FUNCTION get_notification_feed() RETURNS TABLE (
  id UUID,
  type TEXT,
  reference_id UUID,
  latest_actor_id UUID,
  latest_actor_username TEXT,
  latest_actor_avatar TEXT,
  actor_count INT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_three_days_ago TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  UPDATE profiles SET notifications_checked_at = NOW() WHERE id = v_user_id;

  v_three_days_ago := NOW() - INTERVAL '3 days';

  RETURN QUERY
  SELECT
    n.id,
    n.type,
    n.reference_id,
    n.latest_actor_id,
    actor.username AS latest_actor_username,
    actor.avatar_url AS latest_actor_avatar,
    n.actor_count,
    n.created_at,
    n.updated_at,
    n.read_at
  FROM notifications n
  LEFT JOIN profiles actor ON n.latest_actor_id = actor.id
  WHERE n.user_id = v_user_id
    AND (
      -- Activity notifications: 3-day retention
      (n.type IN ('reaction', 'comment', 'tag', 'mention') AND n.updated_at > v_three_days_ago)
      -- Persistent notifications: no time limit
      OR n.type IN ('lockout_started', 'lockout_joined', 'friend_joined', 'connection_request')
    )
  ORDER BY n.updated_at DESC
  LIMIT 50;
END;
$$;
