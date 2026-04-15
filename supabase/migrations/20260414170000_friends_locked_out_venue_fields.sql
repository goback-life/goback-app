-- Add venue_tag_id and is_open_ended to get_friends_locked_out return type.
-- Must DROP first because CREATE OR REPLACE cannot change return type.
DROP FUNCTION IF EXISTS get_friends_locked_out();

CREATE FUNCTION get_friends_locked_out() RETURNS TABLE (
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
  venue_tag_id TEXT,
  is_open_ended BOOLEAN,
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
    ls.id AS lockout_id, ls.user_id, prof.username, prof.avatar_url,
    ls.started_at, ls.ends_at, ls.action_text,
    ls.location_lat, ls.location_lng, ls.location_name,
    ls.venue_tag_id, ls.is_open_ended, ls.participants
  FROM lockout_sessions ls
  JOIN profiles prof ON ls.user_id = prof.id
  WHERE ls.user_id != v_user_id
    AND (ls.is_open_ended OR ls.ends_at > NOW())
    AND ls.post_id IS NULL
    AND ls.completed_at IS NULL
    AND NOT (v_user_id = ANY(ls.participants))
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
    )

  UNION

  -- Part 2: Friends who JOINED lockouts I can see
  SELECT
    ls.id AS lockout_id, participant AS user_id, prof.username, prof.avatar_url,
    ls.started_at, ls.ends_at, ls.action_text,
    ls.location_lat, ls.location_lng, ls.location_name,
    ls.venue_tag_id, ls.is_open_ended, ls.participants
  FROM lockout_sessions ls
  CROSS JOIN LATERAL unnest(ls.participants) AS participant
  JOIN profiles prof ON participant = prof.id
  WHERE participant != v_user_id
    AND ls.user_id != v_user_id
    AND (ls.is_open_ended OR ls.ends_at > NOW())
    AND ls.post_id IS NULL
    AND ls.completed_at IS NULL
    AND NOT (v_user_id = ANY(ls.participants))
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = participant)
         OR (f.user_b_id = v_user_id AND f.user_a_id = participant)
    )

  UNION

  -- Part 3: Co-participants in lockouts I JOINED
  SELECT
    joined_ls.id AS lockout_id, co_participant AS user_id, prof.username, prof.avatar_url,
    joined_ls.started_at, joined_ls.ends_at, joined_ls.action_text,
    joined_ls.location_lat, joined_ls.location_lng, joined_ls.location_name,
    joined_ls.venue_tag_id, joined_ls.is_open_ended, joined_ls.participants
  FROM lockout_sessions joined_ls
  CROSS JOIN LATERAL unnest(joined_ls.participants) AS co_participant
  JOIN profiles prof ON co_participant = prof.id
  WHERE v_user_id = ANY(joined_ls.participants)
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

  -- Part 4: Participants in MY OWN lockout
  SELECT
    my_ls.id AS lockout_id, participant AS user_id, prof.username, prof.avatar_url,
    my_ls.started_at, my_ls.ends_at, my_ls.action_text,
    my_ls.location_lat, my_ls.location_lng, my_ls.location_name,
    my_ls.venue_tag_id, my_ls.is_open_ended, my_ls.participants
  FROM lockout_sessions my_ls
  CROSS JOIN LATERAL unnest(my_ls.participants) AS participant
  JOIN profiles prof ON participant = prof.id
  WHERE my_ls.user_id = v_user_id
    AND (my_ls.is_open_ended OR my_ls.ends_at > NOW())
    AND my_ls.post_id IS NULL
    AND my_ls.completed_at IS NULL

  ORDER BY started_at DESC;
END;
$$;
