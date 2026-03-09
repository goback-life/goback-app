# Push Notifications Implementation Plan

## Current State

Infrastructure is close to ready:

- **In-app notifications**: Fully working. The `notifications` table, aggregation RPC, and UI are all built.
- **Notification types**: Already defined in the enum — `connection_request`, `lockout_started`, `lockout_joined`, `friend_joined`.
- **Device token storage**: Table + RPC functions (`register_device_token`, `unregister_device_token`) exist and are deployed.
- **Push notification service**: Scaffolded in `push_notification_service.dart` but Firebase dependency is commented out — the service is a shell.
- **One edge function exists**: `send-lockout-notification` handles `lockout_started` and is complete but not deployed.

---

## What's Missing (Per Notification)

### 1. Connection Requests (incoming)

**In-app**: Already works. The DB trigger on `connection_requests` INSERT creates a `connection_request` notification, and the UI renders it with Accept/Deny buttons.

**Push**: Needs a new Supabase Edge Function (or extend an existing one):
- Trigger on `connection_requests` INSERT
- Look up receiver's device tokens via `device_tokens` table
- Send FCM push with `{ type: 'connection_request', sender_username, request_id }`
- Effort: ~1 new edge function, modeled after `send-lockout-notification`

### 2. Friend Starts a Lockout

**In-app**: Already works. A DB trigger on `lockout_sessions` INSERT creates `lockout_started` notifications for all friends.

**Push**: The edge function `send-lockout-notification/index.ts` is already written and complete. It:
- Validates >30 min remaining
- Fetches friend device tokens (excluding friends already locked out)
- Sends FCM with `{ type: 'lockout_started', lockout_id, user_id }`

**Needs**: Deploy the function + set `FCM_SERVER_KEY` secret in Supabase.

### 3. Someone Joins Your Lockout (you are locked out / owner)

**In-app**: Already works. The `join_lockout_session` RPC calls `upsert_notification(owner_id, 'lockout_joined', session_id, joiner_id)`.

**Push**: Needs a new Edge Function (or DB webhook handler):
- Trigger on `notifications` INSERT where `type = 'lockout_joined'`, OR on `lockout_sessions` UPDATE when `participants` array changes
- Look up the lockout owner's device tokens
- Send FCM: "USERNAME joined your lockout"
- Consideration: The owner is locked out — do you still want to push? The phone should be down. You may want to make this a silent/low-priority notification that shows when they unlock.

### 4. Friend Joins a Lockout You Can See (you are NOT locked out)

**In-app**: This one does NOT currently exist. There is no notification type or DB trigger for "a friend joined someone else's lockout."

**What's needed**:
- New notification type: Add something like `friend_lockout_joined` to the enum + DB check constraint
- New DB trigger or RPC logic: When `join_lockout_session` runs, notify friends of the joiner (not just the owner) who are not locked out
- New Edge Function: Send push to the joiner's friends with "USERNAME joined OWNER's lockout. Join them!"
- Effort: This is the biggest lift — new notification type, new trigger logic, new edge function, and UI rendering for the new type

---

## Shared Prerequisites (One-Time Work)

| Task | Status |
|------|--------|
| Add `firebase_messaging` dependency to `pubspec.yaml` | Not done |
| Uncomment + complete `PushNotificationService.initialize()` | Scaffolded, needs activation |
| Add `notification` to `PermissionType` enum | Not done |
| Request notification permission in onboarding/auth flow | Not done |
| Register FCM token on login (call `register_device_token` RPC) | Code exists, not wired |
| Handle foreground messages (show local notification or in-app banner) | Not done |
| Handle background/terminated tap (deep-link to relevant screen) | Scaffolded, not implemented |
| Set `FCM_SERVER_KEY` in Supabase secrets | Not done |
| Configure Firebase project for both iOS (APNs) + Android | Unclear if done |
| Deploy edge functions to Supabase | Not done |

---

## Rough Work Breakdown

1. **Firebase/FCM setup** (iOS APNs cert, Android config, `firebase_messaging` package) — platform config work
2. **Activate `PushNotificationService`** — uncomment code, add permission request, wire token registration on login/logout
3. **Deploy existing edge function** for `lockout_started` — just deploy + set secret
4. **New edge function** for `connection_request` push — modeled after existing one
5. **New edge function** for `lockout_joined` push (owner notification) — similar pattern
6. **New notification type + trigger + edge function** for "friend joined a lockout" (non-owner friends) — most complex piece, involves DB migration + new type + new trigger + new edge function + UI

Items 1-2 are one-time foundational work. Items 3-5 are incremental. Item 6 is the only one that requires a new DB migration and notification type.

---

## Key Files

**Notification feature:**
- `lib/core/features/notification/domain/enums/notification_type.dart`
- `lib/core/features/notification/data/services/push_notification_service.dart`
- `lib/core/features/notification/data/services/device_token_service.dart`
- `lib/presentation/pages/notifications/views/notifications_view.dart`

**Lockout feature:**
- `lib/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart`
- `lib/core/features/lockout/data/services/lockout_session_service.dart`

**Edge function:**
- `supabase/functions/send-lockout-notification/index.ts`

**DB migrations:**
- `db/migrations/008_push_notifications.sql`
- `db/migrations/009_notification_system_redesign.sql`
