-- ============================================================================
-- MIGRATION: Member joined notifications (batched push)
-- ============================================================================
-- Adds batched push notifications to all lockout participants when someone
-- joins, replacing the owner-only lockout_joined push.
--
-- Changes:
--   1. Add process_after column to push_notification_queue
--   2. RPC: get_lockout_participant_tokens (tokens for all participants minus exclusions)
--   3. Rewrite join_lockout_session — enqueue member_joined instead of lockout_joined
--   4. SQL function + pg_cron job to flush batched member_joined events
-- ============================================================================


-- ============================================================================
-- 1. ADD process_after COLUMN
-- ============================================================================
-- Defaults to now() so all existing event types process immediately.
-- member_joined events set this to now() + 2 minutes for batching.
ALTER TABLE push_notification_queue
  ADD COLUMN process_after TIMESTAMPTZ NOT NULL DEFAULT now();

-- Replace old index with one that includes process_after for efficient cron queries
DROP INDEX IF EXISTS idx_pnq_unprocessed;
CREATE INDEX idx_pnq_unprocessed
  ON push_notification_queue (process_after, created_at)
  WHERE processed_at IS NULL;


-- ============================================================================
-- 2. RPC: get_lockout_participant_tokens
-- ============================================================================
-- Returns device tokens for all active participants of a lockout session,
-- excluding a given set of user IDs (the joiners who triggered the notification).
CREATE OR REPLACE FUNCTION get_lockout_participant_tokens(
  p_session_id UUID,
  p_exclude_user_ids UUID[]
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
  FROM lockout_participants lp
  JOIN device_tokens dt ON dt.user_id = lp.user_id
  WHERE lp.session_id = p_session_id
    AND lp.left_at IS NULL
    AND NOT (lp.user_id = ANY(p_exclude_user_ids));
END;
$$;

-- Only callable by service_role (edge function) — not exposed to authenticated users
REVOKE EXECUTE ON FUNCTION get_lockout_participant_tokens(UUID, UUID[]) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION get_lockout_participant_tokens(UUID, UUID[]) TO service_role;


-- ============================================================================
-- 3. REWRITE join_lockout_session — member_joined instead of lockout_joined
-- ============================================================================
CREATE OR REPLACE FUNCTION join_lockout_session(p_lockout_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_lockout RECORD;
  v_joined_via UUID;
  v_joiner_username TEXT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  -- Check if user is already in an active lockout (own or joined)
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

  IF v_lockout.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  IF (NOT v_lockout.is_open_ended AND v_lockout.ends_at < NOW()) OR v_lockout.post_id IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  IF v_user_id = ANY(v_lockout.participants) THEN
    RETURN json_build_object('success', true, 'message', 'Already joined this lockout');
  END IF;

  -- Find a friend who is already in the lockout (chain joining)
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

  -- In-app notification to owner (unchanged)
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  -- Look up joiner's username for push notification payload
  SELECT username INTO v_joiner_username
  FROM profiles WHERE id = v_user_id;

  -- Push: notify all lockout participants (batched, 2-min delay)
  INSERT INTO push_notification_queue (event_type, payload, process_after)
  VALUES ('member_joined', jsonb_build_object(
    'session_id', p_lockout_id,
    'joiner_user_id', v_user_id,
    'joiner_username', COALESCE(v_joiner_username, 'Someone')
  ), now() + interval '2 minutes');

  -- Push: notify joiner's friends (immediate, different audience)
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
-- 4. BATCH FLUSH: pg_cron job to process member_joined events
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION flush_member_joined_batch()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_batch RECORD;
BEGIN
  -- Atomically claim ready member_joined events, then group by session.
  -- CTE UPDATE ... RETURNING prevents race conditions if two cron
  -- invocations overlap — each row is claimed exactly once.
  FOR v_batch IN
    WITH claimed AS (
      UPDATE push_notification_queue
      SET processed_at = now()
      WHERE event_type = 'member_joined'
        AND processed_at IS NULL
        AND process_after <= now()
      RETURNING id, payload
    )
    SELECT
      (payload->>'session_id')::UUID AS session_id,
      array_agg(id ORDER BY id) AS event_ids,
      array_agg(payload->>'joiner_username' ORDER BY id) AS usernames,
      array_agg((payload->>'joiner_user_id')::UUID ORDER BY id) AS user_ids
    FROM claimed
    GROUP BY payload->>'session_id'
  LOOP
    -- Insert a single batch event for the edge function to send
    -- process_after defaults to now() so webhook processes immediately
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('member_joined_batch', jsonb_build_object(
      'session_id', v_batch.session_id,
      'joiner_usernames', to_jsonb(v_batch.usernames),
      'joiner_user_ids', to_jsonb(v_batch.user_ids)
    ));
  END LOOP;
END;
$$;

-- Idempotent schedule: remove existing job if present, then create
DO $$
BEGIN
  PERFORM cron.unschedule('flush-member-joined-batch');
EXCEPTION WHEN others THEN NULL;
END;
$$;

SELECT cron.schedule(
  'flush-member-joined-batch',
  '* * * * *',
  $$SELECT flush_member_joined_batch()$$
);
