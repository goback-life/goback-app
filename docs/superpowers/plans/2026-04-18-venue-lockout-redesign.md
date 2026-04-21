# Venue Lockout Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make venue lockouts independent per-user sessions linked by shared venue, remove leader-ends-all, add venue companion display and post auto-tagging.

**Architecture:** Each venue lockout is its own `lockout_sessions` row. "Joining" creates a new session at the same venue (not appending to `participants[]`). Co-location is determined by querying overlapping sessions at the same `venue_tag_id`. Timed lockouts are unchanged.

**Tech Stack:** Supabase RPCs (PostgreSQL), Flutter/Riverpod, NFC MethodChannel

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `supabase/migrations/20260418120000_venue_lockout_independent.sql` | Create | DB: new RPCs, modify existing, notification changes |
| `db/migrations/019_venue_lockout_independent.sql` | Create | Canonical prod copy of above |
| `lib/presentation/pages/manual_lockout/components/friends_locked_out_list.dart` | Modify | Change venue "join" to start new session via NFC |
| `lib/presentation/pages/manual_lockout/components/join_lockout_dialog.dart` | Modify | Update dialog text for venue lockouts |
| `lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart` | Modify | Tap-out calls own-session complete, show companions |
| `lib/core/features/lockout/data/services/lockout_session_service.dart` | Modify | Add `getVenueCompanions`, `notifyVenueDeparture` |
| `lib/core/features/post/domain/hooks/use_post_creation.dart` | Modify | Auto-tag venue companions on post |
| `supabase/functions/send-push-notification/index.ts` | Modify | Handle `venue_departure` notification type |

---

### Task 1: DB Migration — New RPCs and Modified Behavior

**Files:**
- Create: `supabase/migrations/20260418120000_venue_lockout_independent.sql`
- Create: `db/migrations/019_venue_lockout_independent.sql` (identical copy)

- [ ] **Step 1: Write the `get_venue_companions` RPC**

Returns friends at the same venue with overlapping active sessions.

```sql
CREATE OR REPLACE FUNCTION get_venue_companions(p_session_id UUID)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  started_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_venue_tag_id TEXT;
  v_started_at TIMESTAMPTZ;
  v_completed_at TIMESTAMPTZ;
BEGIN
  v_user_id := auth.uid();

  SELECT ls.venue_tag_id, ls.started_at, ls.completed_at
  INTO v_venue_tag_id, v_started_at, v_completed_at
  FROM lockout_sessions ls
  WHERE ls.id = p_session_id AND ls.user_id = v_user_id;

  IF v_venue_tag_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    ls.user_id,
    p.username,
    p.avatar_url,
    ls.started_at
  FROM lockout_sessions ls
  JOIN profiles p ON ls.user_id = p.id
  WHERE ls.venue_tag_id = v_venue_tag_id
    AND ls.id != p_session_id
    AND ls.is_open_ended = true
    AND ls.started_at < COALESCE(v_completed_at, NOW())
    AND COALESCE(ls.completed_at, NOW()) > v_started_at
    AND EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
    );
END;
$$;
```

- [ ] **Step 2: Write the `notify_venue_departure` RPC**

Sends informational push to friends still at the same venue.

```sql
CREATE OR REPLACE FUNCTION notify_venue_departure(p_session_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_venue_tag_id TEXT;
  v_location_name TEXT;
  v_username TEXT;
  v_companion RECORD;
BEGIN
  v_user_id := auth.uid();

  SELECT ls.venue_tag_id, ls.location_name
  INTO v_venue_tag_id, v_location_name
  FROM lockout_sessions ls
  WHERE ls.id = p_session_id AND ls.user_id = v_user_id;

  IF v_venue_tag_id IS NULL THEN
    RETURN;
  END IF;

  SELECT p.username INTO v_username FROM profiles p WHERE p.id = v_user_id;

  -- Notify friends still active at the same venue
  FOR v_companion IN
    SELECT ls.user_id
    FROM lockout_sessions ls
    WHERE ls.venue_tag_id = v_venue_tag_id
      AND ls.id != p_session_id
      AND ls.is_open_ended = true
      AND ls.completed_at IS NULL
      AND EXISTS (
        SELECT 1 FROM friendships f
        WHERE (f.user_a_id = v_user_id AND f.user_b_id = ls.user_id)
           OR (f.user_b_id = v_user_id AND f.user_a_id = ls.user_id)
      )
  LOOP
    INSERT INTO push_notification_queue (event_type, payload)
    VALUES ('venue_departure', jsonb_build_object(
      'user_id', v_companion.user_id,
      'departed_user_id', v_user_id,
      'departed_username', v_username,
      'venue_name', COALESCE(v_location_name, ''),
      'lockout_id', p_session_id
    ));
  END LOOP;
END;
$$;
```

- [ ] **Step 3: Modify `leader_complete_venue_lockout` to only complete the leader**

Replace the current implementation that notifies all participants. For the new model, venue tap-out only completes the caller's own session and sends departure notifications instead.

```sql
CREATE OR REPLACE FUNCTION leader_complete_venue_lockout(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session lockout_sessions%ROWTYPE;
BEGIN
  SELECT * INTO v_session FROM lockout_sessions WHERE id = p_session_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Session not found');
  END IF;

  -- Any user can complete their own session (not just "leader")
  IF v_session.user_id != auth.uid() THEN
    RETURN json_build_object('success', false, 'error', 'Not your session');
  END IF;

  IF v_session.completed_at IS NOT NULL THEN
    RETURN json_build_object('success', true, 'already_completed', true);
  END IF;

  UPDATE lockout_sessions SET completed_at = NOW() WHERE id = p_session_id;

  -- Send departure notifications to friends at same venue
  PERFORM notify_venue_departure(p_session_id);

  RETURN json_build_object('success', true);
END;
$$;
```

- [ ] **Step 4: Save migration files (identical content in both locations)**

- [ ] **Step 5: Push migration to stage**

```bash
supabase link --project-ref aqctvbkmnzarzqnehcza <<< ""
supabase db push
supabase link --project-ref tvrbqsvxfpyfxvbypvtb <<< ""
```

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260418120000_venue_lockout_independent.sql db/migrations/019_venue_lockout_independent.sql
git commit -m "feat: venue lockout independent sessions — DB RPCs"
```

---

### Task 2: Dart Service — New Methods

**Files:**
- Modify: `lib/core/features/lockout/data/services/lockout_session_service.dart`

- [ ] **Step 1: Add `getVenueCompanions` method**

```dart
/// Returns friends at the same venue with overlapping lockout sessions.
Future<List<Map<String, dynamic>>> getVenueCompanions(
    String sessionId) async {
  try {
    final response = await supabase.rpc(
      'get_venue_companions',
      params: {'p_session_id': sessionId},
    );
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  } catch (e) {
    logger.warning('Failed to get venue companions: $e');
    return [];
  }
}
```

- [ ] **Step 2: Add `notifyVenueDeparture` method**

```dart
/// Sends departure notification to friends at the same venue.
Future<void> notifyVenueDeparture(String sessionId) async {
  try {
    await supabase.rpc(
      'notify_venue_departure',
      params: {'p_session_id': sessionId},
    );
  } catch (e) {
    logger.warning('Failed to notify venue departure: $e');
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/features/lockout/data/services/lockout_session_service.dart
git commit -m "feat: add venue companion query and departure notification service methods"
```

---

### Task 3: Change Venue "Join" to Start New Session

**Files:**
- Modify: `lib/presentation/pages/manual_lockout/components/friends_locked_out_list.dart`
- Modify: `lib/presentation/pages/manual_lockout/components/join_lockout_dialog.dart`

- [ ] **Step 1: Update `_handleVenueJoinWithNfc` to start a new session**

In `friends_locked_out_list.dart`, change the `onTagRead` callback. Instead of calling `_performJoin(context, ref, session)` (which calls `joinLockout` and appends to participants), call `startVenueLockout` with the scanned venue data to create an independent session.

```dart
Future<void> _handleVenueJoinWithNfc(
  BuildContext context,
  WidgetRef ref,
  LockoutSessionModel session,
) async {
  final nfcService = ref.read(nfcServiceProvider);

  await nfcService.startReadSession(
    onTagRead: (venue) async {
      if (!context.mounted) return;

      if (venue.venueId != session.venueTagId) {
        MainSnackbar.showError(
          context,
          'You need to be at the same venue to join this lockout',
        );
        return;
      }

      // Tag matches — start independent venue lockout (not join existing)
      try {
        await DndPromptDialog.showIfNeeded(context);
      } catch (_) {}
      if (!context.mounted) return;

      try {
        final notifier = ref.read(manualLockoutNotifierProvider.notifier);
        await notifier.startVenueLockout(venue);
      } catch (e) {
        logger.error('Error starting venue lockout', exception: e);
        if (context.mounted) {
          MainSnackbar.showError(
            context,
            e.toString().contains('already in an active lockout')
                ? translator.translate(
                    'pages.home.lockout_join_error_already_locked')
                : translator.translate(
                    'pages.manual_lockout.friends_locked_out.error'),
          );
        }
      }
    },
    onInvalidTag: () {
      if (context.mounted) {
        MainSnackbar.showError(context, 'This is not a valid GoBack tag');
      }
    },
    onError: () {
      if (context.mounted) {
        MainSnackbar.showError(context, 'NFC scan failed. Please try again.');
      }
    },
  );
}
```

- [ ] **Step 2: Update join dialog text for venue lockouts**

In `join_lockout_dialog.dart`, update the venue lockout description to reflect the new model — you're starting your own lockout, not joining theirs.

Change from:
```
'They are at ${session.locationName ?? 'a venue'}. '
'You will need to scan the GoBack tag at the same venue to join.'
```

To:
```
'They are going back at ${session.locationName ?? 'a venue'}. '
'Scan the GoBack tag there to start your own lockout.'
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/manual_lockout/components/friends_locked_out_list.dart lib/presentation/pages/manual_lockout/components/join_lockout_dialog.dart
git commit -m "feat: venue join starts independent session instead of adding to participants"
```

---

### Task 4: Tap-Out Completes Own Session Only + Departure Notification

**Files:**
- Modify: `lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart`

- [ ] **Step 1: Change `onLockoutComplete` venue path**

Replace the `leaderCompleteVenueLockout` call (which was designed to end for all) with `complete_venue_lockout` (ends own session only) followed by `notifyVenueDeparture`.

Find lines 166-174 in `onLockoutComplete()`:

```dart
// Mark session as completed in DB
final completeSid = sessionId.value;
if (completeSid.isNotEmpty) {
  final sessionService = ref.read(lockoutSessionServiceProvider);
  if (isOpenEnded.value) {
    await sessionService.leaderCompleteVenueLockout(completeSid);
  } else {
    await sessionService.completeTimedLockout(completeSid);
  }
```

Change the venue path to use the modified `leaderCompleteVenueLockout` (which now only completes own + sends departure notif):

No code change needed here — Task 1 already modified the DB RPC to only complete the caller's own session and send departure notifications. The Dart call remains the same.

- [ ] **Step 2: Commit (if any Dart changes needed)**

---

### Task 5: Show Venue Companions on Lockout Screen

**Files:**
- Modify: `lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart`

- [ ] **Step 1: Add companion state and polling**

In the `build()` method of `ManualLockoutView`, add state for companions and a polling effect:

```dart
// Venue companions (friends at same venue)
final venueCompanions = useState<List<Map<String, dynamic>>>([]);

// Poll for venue companions every 30s during open-ended lockouts
useEffect(() {
  if (!isOpenEnded.value || sessionId.value.isEmpty) return null;

  Future<void> fetchCompanions() async {
    final sessionService = ref.read(lockoutSessionServiceProvider);
    final companions = await sessionService.getVenueCompanions(
      sessionId.value,
    );
    venueCompanions.value = companions;
  }

  fetchCompanions();
  final timer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => fetchCompanions(),
  );

  return timer.cancel;
}, [isOpenEnded.value, sessionId.value]);
```

- [ ] **Step 2: Pass companions to the painter or add an overlay**

Add a row of companion avatars above the triangle on the lockout screen. Position it using the same pattern as existing overlays.

```dart
// Layer 5: Venue companions (friends at same venue)
if (isOpenEnded.value &&
    venueCompanions.value.isNotEmpty &&
    !isLockoutComplete.value)
  Positioned(
    bottom: 60 + (screen.width * 0.35) + 20,
    left: 0,
    right: 0,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: venueCompanions.value.map((c) {
        final avatarUrl = c['avatar_url'] as String?;
        final username = c['username'] as String? ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(username.isNotEmpty ? username[0] : '?')
                    : null,
              ),
              const SizedBox(height: 2),
              Text(
                username,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  ),
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart
git commit -m "feat: show venue companions on lockout screen"
```

---

### Task 6: Auto-Tag Venue Companions on Post

**Files:**
- Modify: `lib/core/features/post/domain/hooks/use_post_creation.dart`

- [ ] **Step 1: Fetch venue companions and add to tagged users**

In `publishPostWithExclusions`, after the lockout ID is confirmed, query for venue companions and auto-tag them. Find the section around line 127-136 where `finalTaggedUserIds` is built.

After the existing tag logic, add:

```dart
// Auto-tag venue companions (friends at same venue during lockout)
if (pendingLockoutId != null) {
  final sessionService = ref.read(lockoutSessionServiceProvider);
  final companions = await sessionService.getVenueCompanions(
    pendingLockoutId,
  );
  for (final companion in companions) {
    final companionId = companion['user_id'] as String?;
    if (companionId != null &&
        companionId != user.id &&
        !finalTaggedUserIds.contains(companionId)) {
      finalTaggedUserIds.add(companionId);
    }
  }
  if (companions.isNotEmpty) {
    logger.info(
      'Auto-tagged ${companions.length} venue companions',
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/features/post/domain/hooks/use_post_creation.dart
git commit -m "feat: auto-tag venue companions in lockout posts"
```

---

### Task 7: Push Notification — Venue Departure

**Files:**
- Modify: `supabase/functions/send-push-notification/index.ts`

- [ ] **Step 1: Add `venue_departure` case to `buildMessage`**

```typescript
case 'venue_departure': {
  const { data: tokens } = await supabase.rpc('get_user_device_tokens', { p_user_id: payload.user_id })
  if (!tokens?.length) return null
  const departedUsername = payload.departed_username || 'Someone'
  const venueName = payload.venue_name
  const body = venueName
    ? `${departedUsername} left ${venueName}`
    : `${departedUsername} ended their lockout`
  return {
    title: 'goback update',
    body,
    data: { type: 'venue_departure', lockout_id: payload.lockout_id },
    tokens,
    androidPriority: 'normal' as const,
    iosInterruptionLevel: 'passive' as const,
  }
}
```

Note: `passive` interruption level — this is informational, not urgent. No sound/vibration.

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/send-push-notification/index.ts
git commit -m "feat: venue departure push notification (informational)"
```

---

### Task 8: Update Migration Tracking

- [ ] **Step 1: Update `memory/project_stage_migrations.md`**

Add entry for `20260418120000_venue_lockout_independent`.

- [ ] **Step 2: Commit**

```bash
git add memory/project_stage_migrations.md
git commit -m "chore: track venue lockout independent migration"
```
