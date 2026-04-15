-- STAGE ONLY: Fix the lockout minimum threshold to 55 seconds.
-- Previous migration used '1 minute' which fails with clock skew.
-- Do NOT promote this migration to production.

CREATE OR REPLACE FUNCTION public.enforce_lockout_min_duration()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT NEW.is_open_ended THEN
    IF NEW.ends_at < NOW() + INTERVAL '55 seconds' THEN
      RAISE EXCEPTION 'Timed lockouts must be at least 1 minute (stage)';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
