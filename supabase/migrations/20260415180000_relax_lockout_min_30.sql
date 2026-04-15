-- Relax the timed-lockout minimum from 60 → 30 minutes.
-- The existing trigger `enforce_lockout_min_duration` rejects inserts
-- where ends_at < NOW() + INTERVAL '59 minutes'.
-- Replace it to allow 29 minutes (30-min lockout minus clock skew).

CREATE OR REPLACE FUNCTION public.enforce_lockout_min_duration()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only enforce on timed (non-open-ended) lockouts
  IF NEW.is_open_ended = false AND NEW.ends_at < NOW() + INTERVAL '29 minutes 5 seconds' THEN
    RAISE EXCEPTION 'Timed lockout must be at least 30 minutes';
  END IF;
  RETURN NEW;
END;
$$;
