-- STAGE ONLY: Re-relax lockout minimum after 20260415180000_relax_lockout_min_30.sql.
-- That migration sets a 29-minute minimum for production.
-- On stage, we still want 1-minute lockouts for testing via --dart-define=MIN_LOCKOUT_MINUTES=1.
-- Do NOT promote this migration to production.

CREATE OR REPLACE FUNCTION public.enforce_lockout_min_duration()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT NEW.is_open_ended THEN
    IF NEW.ends_at < NOW() + INTERVAL '1 minute' THEN
      RAISE EXCEPTION 'Timed lockouts must be at least 1 minute (stage)';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
