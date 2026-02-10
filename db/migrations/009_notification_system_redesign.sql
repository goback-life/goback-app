-- ============================================================================
-- MIGRATION 009: Notification System Redesign
-- ============================================================================
-- Updates notification feed RPC to filter activity notifications to 3 days
-- Adds cleanup job for old activity notifications
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Update get_notification_feed with 3-day retention for activity notifications
-- Lockout/friend notifications have no time limit
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

  -- Update notifications_checked_at
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
      -- Activity notifications (reaction, comment, tag, mention): 3-day retention
      (n.type IN ('reaction', 'comment', 'tag', 'mention') AND n.updated_at > v_three_days_ago)
      -- Lockout and friend notifications: no time limit
      OR n.type IN ('lockout_started', 'lockout_joined', 'friend_joined')
    )
  ORDER BY n.updated_at DESC
  LIMIT 50;
END;
$$;

-- ----------------------------------------------------------------------------
-- Cleanup function for old activity notifications
-- Should be run daily via pg_cron or scheduled Edge Function
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleanup_old_activity_notifications() RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted_count INT;
  v_cutoff TIMESTAMPTZ;
BEGIN
  v_cutoff := NOW() - INTERVAL '3 days';

  DELETE FROM notifications
  WHERE type IN ('reaction', 'comment', 'tag', 'mention')
    AND updated_at < v_cutoff;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  RETURN json_build_object(
    'success', true,
    'deleted_count', v_deleted_count,
    'cutoff_time', v_cutoff,
    'executed_at', NOW()
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- Get joinable lockouts (> 30 min remaining) for friends locked out page
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_joinable_friend_lockouts() RETURNS TABLE (
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
  participants UUID[],
  minutes_remaining INT,
  is_joinable BOOLEAN
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
    ls.participants,
    EXTRACT(EPOCH FROM (ls.ends_at - NOW()))::INT / 60 AS minutes_remaining,
    (ls.ends_at > NOW() + INTERVAL '30 minutes') AS is_joinable
  FROM lockout_sessions ls
  JOIN profiles prof ON ls.user_id = prof.id
  WHERE
    ls.ends_at > NOW()
    AND ls.post_id IS NULL
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
    )
  ORDER BY ls.started_at DESC;
END;
$$;
