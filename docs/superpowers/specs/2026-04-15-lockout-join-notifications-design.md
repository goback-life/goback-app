# Lockout Join Notifications

**Date:** 2026-04-15
**Status:** Draft

## Problem

When someone joins a lockout, only the owner receives a push notification (`lockout_joined`). Other participants have no way of knowing someone new joined unless they check the app. We want all lockout members to be notified when someone new joins, without being spammy during bursts of joins.

## Design

### Notification Strategy

Replace the owner-only `lockout_joined` event with a new `member_joined` event that targets all current lockout participants. Use a 2-minute batching window to collapse bursts of joins into a single push notification.

- **Solo join (no other joins within 2 min):** One push per participant — "B joined your lockout"
- **Burst (multiple joins within 2 min):** One push per participant — "B and 4 others joined your lockout"
- **All participants are peers** — owner gets the same treatment as everyone else
- **New members receive future notifications** — once you join, you hear about subsequent joiners
- **Purely push** — no changes to the in-app notification feed
- **Tap action:** Deep link to `FriendsLockedOutRoutable` (`/friends-locked-out`), matching existing lockout notification behavior

### Push Message Content

| Scenario | Title | Body |
|----------|-------|------|
| 1 joiner | `goback` | `B joined your lockout` |
| 2 joiners | `goback` | `B and C joined your lockout` |
| 3+ joiners | `goback` | `B and 4 others joined your lockout` |

"B" is the most recent joiner's display name. Priority: normal.

## Database Changes

### 1. Add `process_after` column to `push_notification_queue`

```sql
ALTER TABLE push_notification_queue
  ADD COLUMN process_after TIMESTAMPTZ NOT NULL DEFAULT now();
```

- Defaults to `now()` so all existing event types process immediately (no behavior change).
- `member_joined` events set `process_after = now() + interval '2 minutes'`.
- Update the unprocessed index:

```sql
DROP INDEX IF EXISTS idx_push_notification_queue_unprocessed;
CREATE INDEX idx_push_notification_queue_unprocessed
  ON push_notification_queue (process_after, created_at)
  WHERE processed_at IS NULL;
```

### 2. Modify `join_lockout_session` RPC

Replace the `lockout_joined` enqueue (owner-only) with `member_joined`:

```sql
INSERT INTO push_notification_queue (event_type, payload, process_after)
VALUES (
  'member_joined',
  jsonb_build_object(
    'session_id', p_lockout_id,
    'joiner_user_id', auth.uid(),
    'joiner_username', (SELECT username FROM profiles WHERE id = auth.uid())
  ),
  now() + interval '2 minutes'
);
```

Remove the existing `lockout_joined` enqueue. Keep `friend_joins_lockout` and `chain_join` events unchanged — they serve a different purpose (notifying friends outside the lockout).

## Edge Function Changes

### 1. Modify `send-push-notification` (webhook-triggered)

Add an early return for deferred events:

```typescript
// Skip events that aren't ready to process yet
if (record.process_after && new Date(record.process_after) > new Date()) {
  return new Response(JSON.stringify({ skipped: true }), { status: 200 });
}
```

All other event types unaffected since their `process_after` defaults to `now()`.

### 2. New edge function: `process-batched-notifications`

Cron-scheduled via `supabase/config.toml` (runs every minute):

```toml
[functions.process-batched-notifications]
schedule = "* * * * *"
```

Logic:
1. Query unprocessed `member_joined` events where `process_after <= now()`
2. Group by `session_id`
3. For each lockout:
   a. Collect joiner usernames from all events in the batch
   b. Get current participants from `lockout_participants` table
   c. Compute recipients = current participants minus the joiners
   d. Look up device tokens for recipients
   e. Build message (1 vs 2 vs 3+ joiners)
   f. Send FCM v1 push to all recipients
   g. Mark all grouped events as `processed_at = now()`
4. Handle stale token cleanup (same as existing function)

Shared FCM v1 auth logic should be extracted into a shared module under `supabase/functions/_shared/` to avoid duplication with `send-push-notification`.

## Flutter Client Changes

### 1. Add `member_joined` to `NotificationType` enum

In `lib/core/features/notification/domain/enums/notification_type.dart`:

```dart
memberJoined('member_joined'),
```

### 2. Update deep link handler in `PushNotificationService`

In `_navigateForType`, add the new case:

```dart
case 'member_joined':
  router.push(const FriendsLockedOutRoutable());
```

### 3. No other client changes

No in-app notification feed changes. No new screens, models, or providers.

## Existing In-App Notification

The `join_lockout_session` RPC currently calls `upsert_notification('lockout_joined', ...)` to create an in-app notification for the owner. This is left unchanged — the owner still gets a record in the notification feed. The new `member_joined` event is push-only and does not create in-app notifications for other participants.

## What's NOT Changing

- `friend_joins_lockout` — still notifies the joiner's friends (outside the lockout) that their friend joined somewhere
- `chain_join` — still notifies the participant who linked the chain joiner
- `lockout_started` — still notifies friends when someone starts a lockout
- In-app notification feed — no changes
- `send-lockout-notification` legacy function — untouched (handles `lockout_started` only)

## Testing

- Join a lockout as solo joiner → all existing participants get push after ~2-3 min
- 5 people join within 1 minute → one batched push to all existing participants
- Joiner does NOT receive a push about their own join
- New joiners receive pushes about subsequent joiners
- Existing notification types still work immediately (no regression)
- Tap notification → opens friends locked out screen
