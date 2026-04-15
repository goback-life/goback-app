-- STAGE ONLY: Remove venue lockout post minimum for testing.
-- Do NOT promote this migration to production.
CREATE OR REPLACE FUNCTION enforce_venue_lockout_min_post_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- No minimum enforced on stage
  RETURN NEW;
END;
$$;
