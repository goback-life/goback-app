-- Hotfix: Run this in Supabase SQL Editor to fix notification feed + add incoming requests RPC

-- Fix 1: get_notification_feed - qualify profiles.id to fix ambiguous column error
DROP FUNCTION IF EXISTS get_notification_feed();

CREATE OR REPLACE FUNCTION get_notification_feed() RETURNS TABLE (
  id UUID, type TEXT, reference_id UUID, latest_actor_id UUID,
  latest_actor_username TEXT, latest_actor_avatar TEXT,
  actor_count INT, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, read_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_user_id UUID; v_three_days_ago TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User not authenticated'; END IF;
  UPDATE profiles SET notifications_checked_at = NOW() WHERE profiles.id = v_user_id;
  v_three_days_ago := NOW() - INTERVAL '3 days';
  RETURN QUERY SELECT n.id, n.type, n.reference_id, n.latest_actor_id,
    actor.username, actor.avatar_url, n.actor_count, n.created_at, n.updated_at, n.read_at
  FROM notifications n LEFT JOIN profiles actor ON n.latest_actor_id = actor.id
  WHERE n.user_id = v_user_id AND (
    (n.type IN ('reaction','comment','tag','mention') AND n.updated_at > v_three_days_ago)
    OR n.type IN ('lockout_started','lockout_joined','friend_joined','connection_request'))
  ORDER BY n.updated_at DESC LIMIT 50;
END; $$;

-- Fix 2: Add incoming connection requests RPC
CREATE OR REPLACE FUNCTION get_incoming_connection_requests() RETURNS TABLE (
  request_id UUID, sender_id UUID, sender_username TEXT,
  sender_avatar_url TEXT, created_at TIMESTAMPTZ, expires_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid UUID;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN RAISE EXCEPTION 'User not authenticated'; END IF;
  RETURN QUERY SELECT cr.id, cr.sender_id, p.username, p.avatar_url, cr.created_at, cr.expires_at
  FROM connection_requests cr JOIN profiles p ON cr.sender_id = p.id
  WHERE cr.receiver_id = v_uid AND cr.expires_at > NOW() ORDER BY cr.created_at DESC;
END; $$;
