-- STAGE ONLY: Fix clock skew between client and server.
-- Use 30-second buffer instead of exact 1-minute check.
-- Do NOT promote this migration to production.
CREATE OR REPLACE FUNCTION enforce_lockout_min_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NOT NEW.is_open_ended THEN
    IF NEW.ends_at < NOW() + INTERVAL '30 seconds' THEN
      RAISE EXCEPTION 'Timed lockouts must be at least 1 minute (stage)';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
