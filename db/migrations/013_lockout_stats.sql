-- ============================================================================
-- Migration 013: Lockout Stats Dashboard
-- ============================================================================
-- Adds a rolling 4-week log of completed lockout sessions and RPCs to query
-- daily/monthly stats for the profile stats tab.
--
-- Retention: rows older than 28 days are pruned daily by pg_cron.
-- RPCs enforce the 28-day window as a safety net.
-- ============================================================================

-- 1. Log table ---------------------------------------------------------------
CREATE TABLE lockout_completed_log (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_date     DATE        NOT NULL,
  duration_minutes INT         NOT NULL DEFAULT 0,
  goback_score     SMALLINT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_lockout_log_user_date
  ON lockout_completed_log (user_id, session_date);

ALTER TABLE lockout_completed_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own lockout logs"
  ON lockout_completed_log FOR SELECT
  USING (auth.uid() = user_id);

-- 2. Patch complete_lockout_session — INSERT log before delete ---------------
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

  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  v_start_time := COALESCE(p_user_started_at, v_session.started_at);
  v_duration_minutes := EXTRACT(EPOCH FROM (LEAST(v_session.ends_at, NOW()) - v_start_time)) / 60;

  -- Log completion BEFORE any deletion
  INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score)
  VALUES (
    v_user_id,
    (v_start_time AT TIME ZONE 'UTC')::date,
    GREATEST(0, v_duration_minutes),
    v_session.goback_score
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

-- 3. Patch update_lockout_weekly_stats — also INSERT log ---------------------
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

  IF v_session.user_id != v_user_id AND NOT (v_user_id = ANY(v_session.participants)) THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  v_start_time := COALESCE(p_user_started_at, v_session.started_at);
  v_duration_minutes := EXTRACT(EPOCH FROM (LEAST(v_session.ends_at, NOW()) - v_start_time)) / 60;

  -- Log completion
  INSERT INTO lockout_completed_log (user_id, session_date, duration_minutes, goback_score)
  VALUES (
    v_user_id,
    (v_start_time AT TIME ZONE 'UTC')::date,
    GREATEST(0, v_duration_minutes),
    v_session.goback_score
  );

  -- Credit weekly minutes
  UPDATE profiles
  SET weekly_lockout_minutes = weekly_lockout_minutes + GREATEST(0, v_duration_minutes)
  WHERE id = v_user_id;

  RETURN json_build_object('success', true, 'minutes_credited', v_duration_minutes);
END;
$$;

-- 4. Daily stats RPC (7 rows, clamped to 28-day window) ---------------------
CREATE OR REPLACE FUNCTION get_lockout_daily_stats(
  p_user_id UUID,
  p_week_start DATE
) RETURNS TABLE(day DATE, minutes INT, session_count INT, avg_score DOUBLE PRECISION)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_earliest DATE := (CURRENT_DATE - INTERVAL '27 days')::date;
  v_clamped  DATE;
BEGIN
  -- Clamp to rolling 4-week window
  v_clamped := GREATEST(p_week_start, v_earliest);

  RETURN QUERY
  SELECT
    d::date AS day,
    COALESCE(SUM(l.duration_minutes), 0)::int AS minutes,
    COUNT(l.id)::int AS session_count,
    AVG(l.goback_score)::double precision AS avg_score
  FROM generate_series(
    v_clamped,
    v_clamped + INTERVAL '6 days',
    INTERVAL '1 day'
  ) AS d
  LEFT JOIN lockout_completed_log l
    ON l.user_id = p_user_id AND l.session_date = d::date
  GROUP BY d
  ORDER BY d;
END;
$$;

-- 5. Monthly summary RPC (rolling 4 weeks, not calendar month) ---------------
CREATE OR REPLACE FUNCTION get_lockout_monthly_summary(
  p_user_id UUID,
  p_year INT,
  p_month INT
) RETURNS TABLE(
  total_minutes INT,
  avg_score DOUBLE PRECISION,
  session_count INT,
  max_duration_minutes INT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cutoff DATE := (CURRENT_DATE - INTERVAL '27 days')::date;
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(l.duration_minutes), 0)::int AS total_minutes,
    AVG(l.goback_score)::double precision AS avg_score,
    COUNT(*)::int AS session_count,
    COALESCE(MAX(l.duration_minutes), 0)::int AS max_duration_minutes
  FROM lockout_completed_log l
  WHERE l.user_id = p_user_id
    AND l.session_date >= v_cutoff;
END;
$$;

-- 6. Daily cleanup via pg_cron — delete rows older than 28 days -------------
-- Supabase projects have pg_cron enabled by default.
-- Runs at 03:00 UTC every day.
SELECT cron.schedule(
  'cleanup-lockout-completed-log',
  '0 3 * * *',
  $$DELETE FROM public.lockout_completed_log WHERE session_date < CURRENT_DATE - INTERVAL '28 days'$$
);
