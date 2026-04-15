-- ============================================================================
-- MIGRATION: Lockout participant notifications + connection request context
-- ============================================================================
-- Adds:
--   1. notify_lockout_participants() function — notifies lockout co-participants
--      when a post is created, using friendship distance to determine
--      notification type (distance 1 → 'tag', distance 2 → 'lockout_tag').
--   2. context_type / context_id columns on connection_requests — allows
--      connection requests to carry context (e.g. originated from a lockout).
--   3. Updates get_notification_feed() to include 'lockout_tag' type.
-- ============================================================================


-- ============================================================================
-- 1. notify_lockout_participants
-- ============================================================================
-- Called after a lockout post is created. Loops through all participants in the
-- lockout session (excluding the author) and sends a notification based on
-- friendship distance:
--
--   Distance 1 (direct friend)  → 'tag' notification
--   Distance 2 (friend-of-joined_via) → 'lockout_tag' notification
--   Distance 3+ → no notification
--
-- Uses SECURITY DEFINER so it can read friendships regardless of caller's RLS.
-- ============================================================================
CREATE OR REPLACE FUNCTION notify_lockout_participants(
  p_post_id UUID,
  p_lockout_id UUID,
  p_author_id UUID
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_participant RECORD;
  v_is_direct_friend BOOLEAN;
  v_is_friend_of_joiner BOOLEAN;
BEGIN
  FOR v_participant IN
    SELECT lp.user_id, lp.joined_via
    FROM lockout_participants lp
    WHERE lp.session_id = p_lockout_id
      AND lp.user_id != p_author_id
      AND lp.left_at IS NULL
  LOOP
    -- Check distance 1: is participant a direct friend of the author?
    v_is_direct_friend := EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = p_author_id AND f.user_b_id = v_participant.user_id)
         OR (f.user_b_id = p_author_id AND f.user_a_id = v_participant.user_id)
    );

    IF v_is_direct_friend THEN
      -- Distance 1: standard tag notification
      PERFORM upsert_notification(
        v_participant.user_id,
        'tag',
        p_post_id,
        p_author_id
      );
    ELSE
      -- Check distance 2: is the author friends with the person who invited
      -- this participant (joined_via)?
      v_is_friend_of_joiner := (
        v_participant.joined_via IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM friendships f
          WHERE (f.user_a_id = p_author_id AND f.user_b_id = v_participant.joined_via)
             OR (f.user_b_id = p_author_id AND f.user_a_id = v_participant.joined_via)
        )
      );

      IF v_is_friend_of_joiner THEN
        -- Distance 2: lockout-specific tag notification
        PERFORM upsert_notification(
          v_participant.user_id,
          'lockout_tag',
          p_post_id,
          p_author_id
        );
      END IF;
      -- Distance 3+: no notification
    END IF;
  END LOOP;
END;
$$;


-- ============================================================================
-- 2. connection_requests context columns
-- ============================================================================
-- Allows connection requests to carry context about where they originated
-- (e.g. context_type = 'lockout', context_id = lockout session UUID).
-- ============================================================================
ALTER TABLE connection_requests
  ADD COLUMN IF NOT EXISTS context_type TEXT,
  ADD COLUMN IF NOT EXISTS context_id UUID;


-- ============================================================================
-- 3. Update get_notification_feed to include 'lockout_tag' type
-- ============================================================================
-- The 'lockout_tag' type behaves like 'tag' — it's an activity notification
-- with 3-day retention.
-- ============================================================================
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

  UPDATE profiles SET notifications_checked_at = NOW() WHERE profiles.id = v_user_id;

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
      (n.type IN ('reaction', 'comment', 'tag', 'mention', 'lockout_tag')
        AND n.updated_at > v_three_days_ago)
      -- Persistent notifications: no time limit
      OR n.type IN ('lockout_started', 'lockout_joined', 'friend_joined', 'connection_request')
    )
  ORDER BY n.updated_at DESC
  LIMIT 50;
END;
$$;
