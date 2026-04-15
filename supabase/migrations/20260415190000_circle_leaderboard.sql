-- ============================================================================
-- MIGRATION: circle_leaderboard — weekly leaderboard for a user's circle
-- ============================================================================
-- Creates:
--   1. Composite index on lockout_completed_log (user_id, session_date,
--      duration_minutes) to accelerate per-user 7-day aggregation.
--   2. get_circle_leaderboard() RPC: returns avg_duration_minutes and
--      session_count for the calling user + all their friends over the
--      last 7 days, sorted by avg_duration_minutes DESC NULLS LAST.
--
-- SECURITY DEFINER is required because lockout_completed_log RLS only
-- permits SELECT where auth.uid() = user_id; the function must read across
-- all circle members on behalf of the caller.
-- ============================================================================

-- 1. Composite index (covers the 7-day aggregation query path)
CREATE INDEX IF NOT EXISTS idx_lockout_log_user_date_duration
  ON lockout_completed_log (user_id, session_date, duration_minutes);

-- 2. Leaderboard function
CREATE OR REPLACE FUNCTION get_circle_leaderboard()
RETURNS TABLE (
  user_id               UUID,
  username              TEXT,
  avatar_url            TEXT,
  avg_duration_minutes  DOUBLE PRECISION,
  session_count         INT,
  is_current_user       BOOLEAN
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
  WITH circle AS (
    -- Friends of the calling user
    SELECT
      CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id
           ELSE f.user_a_id
      END AS member_id
    FROM friendships f
    WHERE f.user_a_id = v_user_id
       OR f.user_b_id = v_user_id

    UNION ALL

    -- The calling user themselves
    SELECT v_user_id AS member_id
  ),
  stats AS (
    SELECT
      lcl.user_id,
      AVG(lcl.duration_minutes)::DOUBLE PRECISION AS avg_duration_minutes,
      COUNT(*)::INT                                AS session_count
    FROM lockout_completed_log lcl
    WHERE lcl.user_id IN (SELECT member_id FROM circle)
      AND lcl.session_date >= (NOW() - INTERVAL '7 days')::DATE
    GROUP BY lcl.user_id
  )
  SELECT
    prof.id                                           AS user_id,
    prof.username                                     AS username,
    prof.avatar_url                                   AS avatar_url,
    s.avg_duration_minutes                            AS avg_duration_minutes,
    COALESCE(s.session_count, 0)                      AS session_count,
    (prof.id = v_user_id)                             AS is_current_user
  FROM circle c
  JOIN profiles prof ON prof.id = c.member_id
  LEFT JOIN stats s   ON s.user_id = c.member_id
  ORDER BY
    s.avg_duration_minutes DESC NULLS LAST,
    prof.username ASC;
END;
$$;
