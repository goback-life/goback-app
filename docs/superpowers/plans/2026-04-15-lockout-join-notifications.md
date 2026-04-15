# Lockout Join Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Notify all lockout participants when someone new joins, with 2-minute batching to prevent spam.

**Architecture:** When a user joins a lockout, the RPC enqueues a `member_joined` event with a 2-minute delay. A pg_cron job runs every minute, groups pending events by lockout, inserts a single `member_joined_batch` event per lockout, and the existing webhook-triggered edge function sends batched FCM pushes to all current participants (minus the joiners).

**Tech Stack:** PostgreSQL (pg_cron), Supabase Edge Functions (Deno/TypeScript), Flutter/Dart

**Spec:** `docs/superpowers/specs/2026-04-15-lockout-join-notifications-design.md`

---

### File Map

| Action | File | Purpose |
|--------|------|---------|
| Create | `supabase/migrations/YYYYMMDDHHMMSS_member_joined_notifications.sql` | All DB changes: column, RPCs, pg_cron |
| Modify | `supabase/functions/send-push-notification/index.ts` | Skip deferred events, handle `member_joined_batch` |
| Modify | `lib/core/features/notification/domain/enums/notification_type.dart` | Add `memberJoined` enum value |
| Modify | `lib/core/features/notification/data/services/push_notification_service.dart` | Deep link for `member_joined` |

---

### Task 1: Migration — `process_after` column and participant token RPC

**Files:**
- Create: `supabase/migrations/YYYYMMDDHHMMSS_member_joined_notifications.sql`

- [ ] **Step 1: Create the migration file with `process_after` column and index**

```sql
-- ============================================================================
-- MIGRATION: Member joined notifications (batched push)
-- ============================================================================
-- Adds batched push notifications to all lockout participants when someone
-- joins, replacing the owner-only lockout_joined push.
--
-- Changes:
--   1. Add process_after column to push_notification_queue
--   2. RPC: get_lockout_participant_tokens (tokens for all participants minus exclusions)
--   3. Rewrite join_lockout_session — enqueue member_joined instead of lockout_joined
--   4. SQL function + pg_cron job to flush batched member_joined events
-- ============================================================================


-- ============================================================================
-- 1. ADD process_after COLUMN
-- ============================================================================
-- Defaults to now() so all existing event types process immediately.
-- member_joined events set this to now() + 2 minutes for batching.
ALTER TABLE push_notification_queue
  ADD COLUMN process_after TIMESTAMPTZ NOT NULL DEFAULT now();

-- Replace old index with one that includes process_after for efficient cron queries
DROP INDEX IF EXISTS idx_pnq_unprocessed;
CREATE INDEX idx_pnq_unprocessed
  ON push_notification_queue (process_after, created_at)
  WHERE processed_at IS NULL;
```

- [ ] **Step 2: Add the `get_lockout_participant_tokens` RPC**

Append to the same migration file:

```sql
-- ============================================================================
-- 2. RPC: get_lockout_participant_tokens
-- ============================================================================
-- Returns device tokens for all active participants of a lockout session,
-- excluding a given set of user IDs (the joiners who triggered the notification).
CREATE OR REPLACE FUNCTION get_lockout_participant_tokens(
  p_session_id UUID,
  p_exclude_user_ids UUID[]
) RETURNS TABLE (
  user_id UUID,
  token TEXT,
  platform TEXT
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT dt.user_id, dt.token, dt.platform
  FROM lockout_participants lp
  JOIN device_tokens dt ON dt.user_id = lp.user_id
  WHERE lp.session_id = p_session_id
    AND lp.left_at IS NULL
    AND NOT (lp.user_id = ANY(p_exclude_user_ids));
END;
$$;
```

- [ ] **Step 3: Verify migration applies cleanly on local Supabase**

Run:
```bash
supabase db reset
```

Expected: migration applies without errors. Verify column exists:
```bash
supabase db query "SELECT column_name, data_type, column_default FROM information_schema.columns WHERE table_name = 'push_notification_queue' AND column_name = 'process_after';"
```

Expected output: one row showing `process_after | timestamp with time zone | now()`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/*_member_joined_notifications.sql
git commit -m "feat: add process_after column and participant token RPC for batched join notifications"
```

---

### Task 2: Migration — Rewrite `join_lockout_session` to enqueue `member_joined`

**Files:**
- Modify: `supabase/migrations/YYYYMMDDHHMMSS_member_joined_notifications.sql`

- [ ] **Step 1: Add the rewritten `join_lockout_session` RPC to the migration**

Append to the migration file. This replaces `lockout_joined` (owner-only push) with `member_joined` (batched push to all participants). Everything else is unchanged from the chain-joining version.

```sql
-- ============================================================================
-- 3. REWRITE join_lockout_session — member_joined instead of lockout_joined
-- ============================================================================
-- CHANGE from previous version (chain_joining migration):
--   - Replace lockout_joined push enqueue with member_joined
--   - member_joined uses process_after = now() + 2 minutes for batching
--   - Remove chain_join push enqueue (redundant — member_joined covers this)
--   - Keep friend_joins_lockout (different audience: joiner's friends outside lockout)
--   - Keep in-app notification to owner (unchanged)
-- ============================================================================
CREATE OR REPLACE FUNCTION join_lockout_session(p_lockout_id UUID) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_lockout RECORD;
  v_joined_via UUID;
  v_joiner_username TEXT;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not authenticated');
  END IF;

  -- Check if user is already in an active lockout (own or joined)
  IF EXISTS (
    SELECT 1 FROM lockout_sessions ls
    WHERE (ls.user_id = v_user_id OR v_user_id = ANY(ls.participants))
      AND (ls.is_open_ended OR ls.ends_at > NOW())
      AND ls.post_id IS NULL
      AND ls.completed_at IS NULL
  ) THEN
    RETURN json_build_object('success', false, 'error', 'You are already in an active lockout');
  END IF;

  SELECT * INTO v_lockout FROM lockout_sessions WHERE id = p_lockout_id;

  IF v_lockout IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout not found');
  END IF;

  IF v_lockout.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  IF (NOT v_lockout.is_open_ended AND v_lockout.ends_at < NOW()) OR v_lockout.post_id IS NOT NULL THEN
    RETURN json_build_object('success', false, 'error', 'Lockout has ended');
  END IF;

  IF v_user_id = ANY(v_lockout.participants) THEN
    RETURN json_build_object('success', true, 'message', 'Already joined this lockout');
  END IF;

  -- Find a friend who is already in the lockout (chain joining)
  SELECT friend_id INTO v_joined_via
  FROM (
    SELECT v_lockout.user_id AS friend_id
    UNION ALL
    SELECT unnest(v_lockout.participants) AS friend_id
  ) candidates
  WHERE EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = v_user_id AND f.user_b_id = candidates.friend_id)
       OR (f.user_b_id = v_user_id AND f.user_a_id = candidates.friend_id)
  )
  LIMIT 1;

  IF v_joined_via IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'You must be friends with someone in this lockout');
  END IF;

  IF v_joined_via = v_lockout.user_id THEN
    v_joined_via := NULL;
  END IF;

  -- Dual-write: add to participants array (backwards compat)
  UPDATE lockout_sessions
  SET participants = array_append(participants, v_user_id)
  WHERE id = p_lockout_id;

  -- Dual-write: insert into lockout_participants (normalised table)
  INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
  VALUES (p_lockout_id, v_user_id, v_joined_via, NOW())
  ON CONFLICT (session_id, user_id) DO NOTHING;

  -- In-app notification to owner (unchanged)
  PERFORM upsert_notification(v_lockout.user_id, 'lockout_joined', p_lockout_id, v_user_id);

  -- Look up joiner's username for push notification payload
  SELECT username INTO v_joiner_username
  FROM profiles WHERE id = v_user_id;

  -- Push: notify all lockout participants (batched, 2-min delay)
  INSERT INTO push_notification_queue (event_type, payload, process_after)
  VALUES ('member_joined', jsonb_build_object(
    'session_id', p_lockout_id,
    'joiner_user_id', v_user_id,
    'joiner_username', COALESCE(v_joiner_username, 'Someone')
  ), now() + interval '2 minutes');

  -- Push: notify joiner's friends (immediate, different audience)
  INSERT INTO push_notification_queue (event_type, payload)
  VALUES ('friend_joins_lockout', jsonb_build_object(
    'joiner_id', v_user_id,
    'owner_id', v_lockout.user_id,
    'lockout_id', p_lockout_id
  ));

  RETURN json_build_object('success', true, 'message', 'Joined lockout');
END;
$$;
```

- [ ] **Step 2: Verify migration applies and RPC compiles**

Run:
```bash
supabase db reset
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/*_member_joined_notifications.sql
git commit -m "feat: rewrite join_lockout_session to enqueue member_joined with 2-min delay"
```

---

### Task 3: Migration — pg_cron batch flush function and schedule

**Files:**
- Modify: `supabase/migrations/YYYYMMDDHHMMSS_member_joined_notifications.sql`

- [ ] **Step 1: Add the batch flush function and pg_cron schedule**

Append to the migration file:

```sql
-- ============================================================================
-- 4. BATCH FLUSH: pg_cron job to process member_joined events
-- ============================================================================
-- Runs every minute. Groups pending member_joined events by session_id,
-- marks them as processed, and inserts a single member_joined_batch event
-- per lockout for the webhook-triggered edge function to send.
-- ============================================================================

-- Enable pg_cron if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION flush_member_joined_batch()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_batch RECORD;
  v_joiner_usernames TEXT[];
  v_joiner_user_ids UUID[];
BEGIN
  -- Process each lockout session that has ready member_joined events
  FOR v_batch IN
    SELECT
      (payload->>'session_id')::UUID AS session_id,
      array_agg(id) AS event_ids,
      array_agg(payload->>'joiner_username') AS usernames,
      array_agg((payload->>'joiner_user_id')::UUID) AS user_ids
    FROM push_notification_queue
    WHERE event_type = 'member_joined'
      AND processed_at IS NULL
      AND process_after <= now()
    GROUP BY payload->>'session_id'
  LOOP
    -- Mark original events as processed (claim them)
    UPDATE push_notification_queue
    SET processed_at = now()
    WHERE id = ANY(v_batch.event_ids)
      AND processed_at IS NULL;

    -- Insert a single batch event for the edge function to send
    -- process_after defaults to now() so webhook processes immediately
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('member_joined_batch', jsonb_build_object(
      'session_id', v_batch.session_id,
      'joiner_usernames', to_jsonb(v_batch.usernames),
      'joiner_user_ids', to_jsonb(v_batch.user_ids)
    ));
  END LOOP;
END;
$$;

-- Schedule: run every minute
SELECT cron.schedule(
  'flush-member-joined-batch',
  '* * * * *',
  $$SELECT flush_member_joined_batch()$$
);
```

- [ ] **Step 2: Verify migration applies**

Run:
```bash
supabase db reset
```

Expected: no errors. Verify cron job exists:
```bash
supabase db query "SELECT jobname, schedule, command FROM cron.job WHERE jobname = 'flush-member-joined-batch';"
```

Expected: one row with `* * * * *` schedule.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/*_member_joined_notifications.sql
git commit -m "feat: add pg_cron job to batch-flush member_joined events every minute"
```

---

### Task 4: Edge function — Skip deferred events and handle `member_joined_batch`

**Files:**
- Modify: `supabase/functions/send-push-notification/index.ts:149-243` (buildMessage switch)
- Modify: `supabase/functions/send-push-notification/index.ts:248-310` (main handler)

- [ ] **Step 1: Add `process_after` to the `WebhookPayload` record type**

In `supabase/functions/send-push-notification/index.ts`, update the `record` type inside `WebhookPayload` (line 17-24):

```typescript
  record: {
    id: string
    event_type: string
    payload: Record<string, string>
    created_at: string
    processed_at: string | null
    process_after: string
  }
```

- [ ] **Step 2: Add early return for deferred events in the main handler**

In the main handler (after line 256 `const { id, event_type, payload } = webhookPayload.record`), add:

```typescript
    // Skip events that aren't ready to process yet (batched by pg_cron)
    if (webhookPayload.record.process_after && new Date(webhookPayload.record.process_after) > new Date()) {
      return new Response(JSON.stringify({ message: 'Deferred for batching' }), { status: 200 })
    }
```

- [ ] **Step 3: Add `member_joined_batch` case to `buildMessage`**

Add this case before the `default:` case in the `buildMessage` switch (before line 240):

```typescript
    case 'member_joined_batch': {
      const sessionId = payload.session_id
      const joinerUsernames: string[] = JSON.parse(payload.joiner_usernames as string ?? '[]')
      const joinerUserIds: string[] = JSON.parse(payload.joiner_user_ids as string ?? '[]')

      if (!joinerUsernames.length || !joinerUserIds.length) return null

      // Get device tokens for all current participants, excluding the joiners
      const { data: tokens } = await supabase.rpc('get_lockout_participant_tokens', {
        p_session_id: sessionId,
        p_exclude_user_ids: joinerUserIds,
      })
      if (!tokens?.length) return null

      // Build message based on joiner count
      const count = joinerUsernames.length
      const latest = joinerUsernames[joinerUsernames.length - 1]
      let body: string
      if (count === 1) {
        body = `${latest} joined your lockout`
      } else if (count === 2) {
        body = `${joinerUsernames[0]} and ${joinerUsernames[1]} joined your lockout`
      } else {
        body = `${latest} and ${count - 1} others joined your lockout`
      }

      return {
        title: 'goback',
        body,
        data: { type: 'member_joined', lockout_id: sessionId },
        tokens,
        androidPriority: 'normal',
        iosInterruptionLevel: 'passive',
      }
    }
```

- [ ] **Step 4: Remove the old `lockout_joined` case from `buildMessage`**

Delete the `lockout_joined` case (lines 179-191) since it's replaced by `member_joined_batch`. The RPC no longer enqueues `lockout_joined` events, so this code is dead.

Also remove the `chain_join` case if it exists — the RPC no longer enqueues `chain_join` events either.

- [ ] **Step 5: Deploy and test the edge function locally**

Run:
```bash
supabase functions serve send-push-notification --env-file supabase/.env
```

Manually test with a curl to verify the deferred skip logic:
```bash
curl -X POST http://localhost:54321/functions/v1/send-push-notification \
  -H "Content-Type: application/json" \
  -d '{"type":"INSERT","table":"push_notification_queue","record":{"id":"test","event_type":"member_joined","payload":{"session_id":"test"},"created_at":"2026-04-15T00:00:00Z","processed_at":null,"process_after":"2099-01-01T00:00:00Z"}}'
```

Expected response: `{"message":"Deferred for batching"}`

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/send-push-notification/index.ts
git commit -m "feat: handle member_joined_batch in edge function with deferred event skip"
```

---

### Task 5: Flutter — Add `memberJoined` notification type and deep link

**Files:**
- Modify: `lib/core/features/notification/domain/enums/notification_type.dart:2-9`
- Modify: `lib/core/features/notification/data/services/push_notification_service.dart:196-207`

- [ ] **Step 1: Add `memberJoined` to `NotificationType` enum**

In `lib/core/features/notification/domain/enums/notification_type.dart`, add the new value after `connectionRequest`:

```dart
enum NotificationType {
  reaction('reaction'),
  tag('tag'),
  comment('comment'),
  lockoutStarted('lockout_started'),
  lockoutJoined('lockout_joined'),
  friendJoined('friend_joined'),
  connectionRequest('connection_request'),
  memberJoined('member_joined');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () =>
          throw ArgumentError('Invalid notification type value: $value'),
    );
  }
}
```

- [ ] **Step 2: Add `member_joined` case to `_navigateForType`**

In `lib/core/features/notification/data/services/push_notification_service.dart`, update `_navigateForType` (line 195-208):

```dart
  void _navigateForType(String type) {
    switch (type) {
      case 'lockout_started':
      case 'lockout_joined':
      case 'friend_joins_lockout':
      case 'member_joined':
        router.push(const FriendsLockedOutRoutable());
      case 'lockout_completed':
        onLockoutCompleted?.call();
        router.push(const FriendsLockedOutRoutable());
      case 'connection_request':
        router.push(const NotificationsRoutable());
    }
  }
```

- [ ] **Step 3: Verify the app builds**

Run:
```bash
fvm flutter analyze
```

Expected: no new warnings or errors from these changes.

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/notification/domain/enums/notification_type.dart lib/core/features/notification/data/services/push_notification_service.dart
git commit -m "feat: add member_joined notification type and deep link handler"
```

---

### Task 6: Deploy and verify end-to-end

- [ ] **Step 1: Push migration to staging**

```bash
supabase db push --linked
```

Expected: migration applies cleanly. Verify:
```bash
supabase db query --linked "SELECT column_name FROM information_schema.columns WHERE table_name = 'push_notification_queue' AND column_name = 'process_after';"
```

- [ ] **Step 2: Verify pg_cron job is active on staging**

```bash
supabase db query --linked "SELECT jobname, schedule FROM cron.job WHERE jobname = 'flush-member-joined-batch';"
```

Expected: one row.

- [ ] **Step 3: Deploy edge function to staging**

```bash
supabase functions deploy send-push-notification --linked
```

- [ ] **Step 4: Update stage migrations tracker**

Add to `memory/project_stage_migrations.md`:
```
- `YYYYMMDDHHMMSS_member_joined_notifications` — member joined batch notifications (2026-04-15)
```

- [ ] **Step 5: Test end-to-end on staging**

1. User A starts a lockout (> 30 min)
2. User B joins → verify `member_joined` event appears in `push_notification_queue` with `process_after` ~2 min in future
3. Wait ~2 minutes for pg_cron to fire
4. Verify `member_joined_batch` event appears with `processed_at` set
5. Verify User A received a push notification: "B joined your lockout"
6. User C joins within 2 minutes of B → verify both get batched
7. After flush: User A receives one push: "B and C joined your lockout"
8. User D joins > 2 minutes later → User A, B, C each receive: "D joined your lockout"
9. Tap notification → app opens to Friends Locked Out screen

- [ ] **Step 6: Commit any fixes and final commit**

```bash
git add -A
git commit -m "chore: deploy lockout join notifications to staging"
```
