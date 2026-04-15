-- STAGE ONLY: Relax lockout minimums for testing.
-- Do NOT promote this migration to production.

-- Timed lockouts: 1 minute minimum (prod: 1 hour)
CREATE OR REPLACE FUNCTION enforce_lockout_min_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NOT NEW.is_open_ended THEN
    IF NEW.ends_at < NOW() + INTERVAL '1 minute' THEN
      RAISE EXCEPTION 'Timed lockouts must be at least 1 minute (stage)';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Venue lockout posts: no minimum (prod: 10 minutes)
CREATE OR REPLACE FUNCTION enforce_venue_lockout_min_post_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- No minimum enforced on stage
  RETURN NEW;
END;
$$;
