-- ============================================================================
-- MIGRATION 016: NFC Venue Tags
-- ============================================================================
-- Adds venues table and NFC-related columns to lockout_sessions.
-- Venue-initiated lockouts are open-ended (no fixed end time).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. venues table
-- ----------------------------------------------------------------------------
CREATE TABLE venues (
  id TEXT PRIMARY KEY,         -- 8-char lowercase hex written to NFC tag
  name TEXT NOT NULL,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Venues are admin-managed — no public access
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "venues_read_all"
  ON venues FOR SELECT
  USING (true);

-- ----------------------------------------------------------------------------
-- 2. Add venue columns to lockout_sessions
-- ----------------------------------------------------------------------------
ALTER TABLE lockout_sessions
  ADD COLUMN venue_tag_id TEXT REFERENCES venues(id),
  ADD COLUMN is_open_ended BOOLEAN NOT NULL DEFAULT false;

-- ----------------------------------------------------------------------------
-- 3. Update lockout_started trigger to include location_name in payload
--    so the push notification edge function can include venue in the body.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_enqueue_lockout_started()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Enqueue for open-ended OR regular lockouts > 30 min remaining
  IF NEW.is_open_ended OR NEW.ends_at > NOW() + INTERVAL '30 minutes' THEN
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('lockout_started', jsonb_build_object(
      'user_id', NEW.user_id,
      'lockout_id', NEW.id,
      'location_name', COALESCE(NEW.location_name, ''),
      'is_open_ended', NEW.is_open_ended
    ));
  END IF;

  RETURN NEW;
END;
$$;
