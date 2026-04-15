-- ============================================================================
-- MIGRATION 017: Lockout Duration Constraints
-- ============================================================================
-- Enforces minimum lockout durations at the database level:
--   - Timed lockouts: minimum 1 hour (60 minutes)
--   - Open-ended (venue/NFC) lockouts: no duration constraint at insert
--     (enforced client-side: "Share" option hidden if < 10 minutes elapsed)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Enforce minimum 1-hour duration for timed (non-open-ended) lockouts
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enforce_lockout_min_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Only enforce on timed lockouts (open-ended have a sentinel ends_at)
  IF NOT NEW.is_open_ended THEN
    IF NEW.ends_at < NOW() + INTERVAL '59 minutes' THEN
      RAISE EXCEPTION 'Timed lockouts must be at least 1 hour';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_lockout_min_duration ON lockout_sessions;
CREATE TRIGGER trg_enforce_lockout_min_duration
  BEFORE INSERT ON lockout_sessions
  FOR EACH ROW EXECUTE FUNCTION enforce_lockout_min_duration();

-- ----------------------------------------------------------------------------
-- 2. Enforce minimum 10-minute elapsed time for posting from open-ended lockouts
--    Posts linked to open-ended sessions that lasted < 10 minutes are rejected.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enforce_venue_lockout_min_post_duration()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_session lockout_sessions%ROWTYPE;
BEGIN
  IF NEW.lockout_id IS NOT NULL THEN
    SELECT * INTO v_session FROM lockout_sessions WHERE id = NEW.lockout_id;
    IF FOUND AND v_session.is_open_ended THEN
      -- Check elapsed time since session started
      IF v_session.started_at IS NOT NULL
         AND NOW() - v_session.started_at < INTERVAL '10 minutes' THEN
        RAISE EXCEPTION 'Venue lockouts must last at least 10 minutes before posting';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_venue_lockout_min_post_duration ON posts;
CREATE TRIGGER trg_enforce_venue_lockout_min_post_duration
  BEFORE INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION enforce_venue_lockout_min_post_duration();
