-- ============================================================================
-- MIGRATION: lockout_participants table
-- ============================================================================
-- Introduces a normalised participant table for lockout sessions, replacing
-- the UUID[] array approach for cross-circle tagging support.
--
-- The existing lockout_sessions.participants column is KEPT for backwards
-- compatibility (dual-write pattern). This table runs alongside it.
--
-- Changes:
--   1.  CREATE TABLE lockout_participants
--   2.  Indexes for user and session lookups
--   3.  RLS policies (select, insert, update)
--   4.  Trigger: auto-insert owner row on lockout_sessions INSERT
--   5.  Replace update_lockout_score() to write to lockout_participants
--   6.  Backfill existing active sessions
-- ============================================================================


-- ============================================================================
-- 1. CREATE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS lockout_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES lockout_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  joined_via UUID REFERENCES profiles(id) ON DELETE SET NULL,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  goback_score SMALLINT,
  battery_was_charging BOOLEAN,
  step_count SMALLINT,
  UNIQUE (session_id, user_id)
);


-- ============================================================================
-- 2. INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_lockout_participants_user
  ON lockout_participants (user_id);

CREATE INDEX IF NOT EXISTS idx_lockout_participants_session
  ON lockout_participants (session_id);


-- ============================================================================
-- 3. RLS POLICIES
-- ============================================================================
ALTER TABLE lockout_participants ENABLE ROW LEVEL SECURITY;

-- SELECT: user can read rows if they are owner or participant of the session
-- NOTE: uses lockout_sessions.participants array (not self-referential) to avoid
-- circular RLS evaluation that would silently block co-participant reads.
CREATE POLICY "Participants can view own session participants"
  ON lockout_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM lockout_sessions ls
      WHERE ls.id = lockout_participants.session_id
        AND (
          ls.user_id = auth.uid()
          OR auth.uid() = ANY(ls.participants)
        )
    )
  );

-- SELECT: user can read participants if session owner is their friend
CREATE POLICY "Friends can view session participants"
  ON lockout_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM lockout_sessions ls
      JOIN friendships f
        ON (f.user_a_id = auth.uid() AND f.user_b_id = ls.user_id)
        OR (f.user_b_id = auth.uid() AND f.user_a_id = ls.user_id)
      WHERE ls.id = lockout_participants.session_id
    )
  );

-- INSERT: only for your own user_id
CREATE POLICY "Users can insert own participant row"
  ON lockout_participants FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- UPDATE: only your own row
CREATE POLICY "Users can update own participant row"
  ON lockout_participants FOR UPDATE
  USING (user_id = auth.uid());


-- ============================================================================
-- 4. TRIGGER: auto-insert owner row on lockout_sessions INSERT
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_lockout_owner_participant()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
  VALUES (NEW.id, NEW.user_id, NULL, NEW.started_at)
  ON CONFLICT (session_id, user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Drop if it already exists (idempotent)
DROP TRIGGER IF EXISTS trg_lockout_owner_participant ON lockout_sessions;

CREATE TRIGGER trg_lockout_owner_participant
  AFTER INSERT ON lockout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION fn_lockout_owner_participant();


-- ============================================================================
-- 5. REPLACE update_lockout_score() — write to lockout_participants
-- ============================================================================
-- Keeps the same function signature so existing client code works unchanged.
-- Writes score data to lockout_participants instead of lockout_sessions.
-- Also writes to lockout_sessions for backwards compatibility (dual-write).
CREATE OR REPLACE FUNCTION update_lockout_score(
  p_session_id UUID,
  p_score INT,
  p_battery_was_charging BOOLEAN DEFAULT NULL,
  p_step_count INT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session RECORD;
  v_clamped_score SMALLINT;
  v_clamped_steps SMALLINT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF v_session IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  -- Clamp values
  v_clamped_score := LEAST(100, GREATEST(0, p_score))::SMALLINT;
  v_clamped_steps := CASE WHEN p_step_count IS NOT NULL
                          THEN LEAST(32767, GREATEST(0, p_step_count))::SMALLINT
                          ELSE NULL END;

  -- Primary write: lockout_participants
  UPDATE lockout_participants
  SET goback_score = v_clamped_score,
      battery_was_charging = p_battery_was_charging,
      step_count = v_clamped_steps
  WHERE session_id = p_session_id AND user_id = v_user_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Not part of this lockout');
  END IF;

  -- Backwards-compat write: lockout_sessions (owner only, preserves old behaviour)
  IF v_session.user_id = v_user_id THEN
    UPDATE lockout_sessions
    SET goback_score = v_clamped_score,
        battery_was_charging = p_battery_was_charging,
        step_count = v_clamped_steps
    WHERE id = p_session_id;
  END IF;

  RETURN json_build_object('success', true);
END;
$$;


-- ============================================================================
-- 6. BACKFILL existing active sessions
-- ============================================================================
-- Insert owner rows for all active sessions that don't already have one.
INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at, goback_score, battery_was_charging, step_count)
SELECT
  ls.id,
  ls.user_id,
  NULL,
  ls.started_at,
  ls.goback_score,
  ls.battery_was_charging,
  ls.step_count
FROM lockout_sessions ls
WHERE ls.completed_at IS NULL
  AND (ls.is_open_ended OR ls.ends_at > NOW())
ON CONFLICT (session_id, user_id) DO NOTHING;

-- Insert participant rows for joiners in active sessions.
-- joined_via is set to the session owner (they joined via the owner's lockout).
-- joined_at defaults to started_at as best approximation (exact join time not stored).
INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
SELECT
  ls.id,
  participant_id,
  ls.user_id,
  ls.started_at
FROM lockout_sessions ls
CROSS JOIN LATERAL unnest(ls.participants) AS participant_id
WHERE ls.completed_at IS NULL
  AND (ls.is_open_ended OR ls.ends_at > NOW())
ON CONFLICT (session_id, user_id) DO NOTHING;


-- ============================================================================
-- VERIFICATION NOTES
-- ============================================================================
--
-- After running this migration:
--
-- 1. lockout_participants table:
--    - One row per user per session (UNIQUE constraint)
--    - Owner rows have joined_via = NULL
--    - Joiner rows have joined_via = the profile that invited them
--
-- 2. Trigger:
--    - Every new lockout_sessions INSERT auto-creates an owner participant row
--    - ON CONFLICT DO NOTHING makes it safe if row already exists
--
-- 3. update_lockout_score():
--    - Dual-writes to both lockout_participants (primary) and lockout_sessions
--    - Returns error if caller has no participant row (NOT FOUND)
--    - Backwards-compat write only for session owner
--
-- 4. RLS:
--    - Co-participants can see each other's rows
--    - Friends of the session owner can see participant rows
--    - Only your own row can be inserted/updated
--
-- 5. Backfill:
--    - All active sessions get owner + participant rows
--    - ON CONFLICT DO NOTHING makes re-running safe
--
-- ============================================================================
