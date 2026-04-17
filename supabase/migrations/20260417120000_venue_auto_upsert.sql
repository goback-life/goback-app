-- ============================================================================
-- Auto-upsert venue on lockout creation
-- ============================================================================
-- The NFC tag contains venue_id + venue_name. When a user starts a venue
-- lockout, we auto-create the venue row if it doesn't exist. This avoids
-- FK violations on lockout_sessions.venue_tag_id → venues.id.
-- ============================================================================

-- RPC: ensures the venue exists before a lockout session references it.
-- Called from the client before createSession.
CREATE OR REPLACE FUNCTION upsert_venue(p_venue_id TEXT, p_venue_name TEXT)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO venues (id, name)
  VALUES (p_venue_id, p_venue_name)
  ON CONFLICT (id) DO NOTHING;
END;
$$;
