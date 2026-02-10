-- ============================================================================
-- MIGRATION 008: Push Notifications (Device Tokens)
-- ============================================================================
-- Creates device_tokens table for FCM token storage
-- Updates lockout notification trigger to support push
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Device tokens table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL, -- 'ios' or 'android'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_token UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens (user_id);

-- Updated_at trigger
CREATE TRIGGER trg_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ----------------------------------------------------------------------------
-- RLS for device_tokens
-- ----------------------------------------------------------------------------
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own device tokens"
  ON device_tokens FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own device tokens"
  ON device_tokens FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own device tokens"
  ON device_tokens FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own device tokens"
  ON device_tokens FOR DELETE
  USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- RPC to register device token
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION register_device_token(
  p_token TEXT,
  p_platform TEXT
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  -- Upsert the token
  INSERT INTO device_tokens (user_id, token, platform)
  VALUES (v_user_id, p_token, p_platform)
  ON CONFLICT (user_id, token) DO UPDATE SET
    platform = p_platform,
    updated_at = NOW();

  RETURN json_build_object('success', true);
END;
$$;

-- ----------------------------------------------------------------------------
-- RPC to unregister device token (for logout)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unregister_device_token(
  p_token TEXT
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  DELETE FROM device_tokens
  WHERE user_id = v_user_id AND token = p_token;

  RETURN json_build_object('success', true);
END;
$$;

-- ----------------------------------------------------------------------------
-- RPC to get device tokens for push notification
-- Used by Edge Function to send push notifications
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_friend_device_tokens_for_lockout(
  p_lockout_user_id UUID
) RETURNS TABLE (
  user_id UUID,
  token TEXT,
  platform TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Get device tokens for all friends of the lockout user
  -- who are NOT currently in an active lockout themselves
  RETURN QUERY
  SELECT
    dt.user_id,
    dt.token,
    dt.platform
  FROM device_tokens dt
  WHERE
    -- Is a friend of the lockout user
    EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = p_lockout_user_id AND f.user_b_id = dt.user_id)
         OR (f.user_b_id = p_lockout_user_id AND f.user_a_id = dt.user_id)
    )
    -- Is NOT in an active lockout themselves
    AND NOT EXISTS (
      SELECT 1 FROM lockout_sessions ls
      WHERE ls.user_id = dt.user_id
        AND ls.ends_at > NOW()
        AND ls.post_id IS NULL
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- Check if lockout is joinable (> 30 min remaining)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_lockout_joinable(
  p_lockout_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ends_at TIMESTAMPTZ;
  v_post_id UUID;
BEGIN
  SELECT ends_at, post_id INTO v_ends_at, v_post_id
  FROM lockout_sessions
  WHERE id = p_lockout_id;

  IF v_ends_at IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Not joinable if already completed (has post)
  IF v_post_id IS NOT NULL THEN
    RETURN FALSE;
  END IF;

  -- Joinable if > 30 minutes remaining
  RETURN v_ends_at > NOW() + INTERVAL '30 minutes';
END;
$$;
