# Venue Lockout Redesign — Independent Sessions with Shared Venue Context

## Summary

Venue (NFC tap) lockouts become independent per-user sessions linked by a shared `venue_tag_id`. There is no leader/joiner hierarchy — each person starts and ends their own lockout by scanning the venue's NFC tag. The social layer shows who else is at the same venue, and posts auto-tag friends who overlapped at the venue.

Timed (countdown) lockouts are unchanged — shared session with `participants[]`, leader ends for all.

## Core Model Change

**Before:** "Join" adds you to the owner's `participants[]` array. One session, one `completed_at`.

**After:** "Join" creates a brand new `lockout_sessions` row for you at the same venue. Each person has their own `started_at`, `completed_at`, `goback_score`. The connection between co-located users is the shared `venue_tag_id` + overlapping time, not a participants array.

## Data Model

### `lockout_sessions` table — no schema change needed

Existing columns already support this:
- `venue_tag_id` — links sessions at the same venue
- `is_open_ended` — true for venue lockouts
- `completed_at` — each person's own end time
- `started_at` — each person's own start time
- `user_id` — session owner (always the person locked out)
- `participants` — **unused for venue lockouts** (still used for timed)

### New query: co-located users

```sql
-- Find friends at the same venue during my lockout
SELECT ls.user_id, ls.started_at, ls.completed_at, p.username, p.avatar_url
FROM lockout_sessions ls
JOIN profiles p ON ls.user_id = p.id
WHERE ls.venue_tag_id = $my_venue_tag_id
  AND ls.id != $my_session_id
  AND ls.is_open_ended = true
  -- Overlapping time: their session started before I ended, and ended (or is still active) after I started
  AND ls.started_at < COALESCE($my_completed_at, NOW())
  AND COALESCE(ls.completed_at, NOW()) > $my_started_at
  -- Must be in my network
  AND EXISTS (
    SELECT 1 FROM friendships f
    WHERE (f.user_a_id = auth.uid() AND f.user_b_id = ls.user_id)
       OR (f.user_b_id = auth.uid() AND f.user_a_id = ls.user_id)
  );
```

## Flows

### 1. Start venue lockout (unchanged)

User scans NFC tag → `upsert_venue` → `createSession(isOpenEnded: true, venueTagId: X)` → own session created.

### 2. "Join" at same venue

User sees friend locked out at a venue in the friends list → taps "Join" → dialog says "Scan the GoBack tag at [venue name]" → NFC scan → verify `venueId` matches friend's `venue_tag_id` → **create a NEW session** for this user at the same venue (not add to participants).

Changes from current flow:
- Instead of calling `joinSession(sessionId)` (which adds to `participants[]`), call `startVenueLockout(venue)` to create an independent session
- The friend's session ID is irrelevant — we just need the venue info
- No "already in active lockout" conflict since it's a new session (unless user is already locked out elsewhere)

### 3. End venue lockout (each person independently)

User taps triangle → NFC scan → `completed_at = NOW()` on **their own session only**.

No `leader_complete_venue_lockout` needed for venue lockouts — that RPC is only for timed lockouts.

### 4. Notifications

When someone at the venue taps out:
- Push notification to friends still at the same venue: "[Username] left [venue name]"
- Informational only — no action needed from recipients
- Recipients' lockouts continue unaffected

### 5. Lockout screen — show co-located friends

While locked out at a venue, the lockout screen shows who else is at the same venue:
- Query `lockout_sessions` for same `venue_tag_id`, `completed_at IS NULL`, friends only
- Display avatars/names below the timer
- Real-time updates: when someone joins or leaves, the list updates (poll every 30s or on push notification)

### 6. Post auto-tagging

When creating a post from a venue lockout:
- Query for friends who had overlapping sessions at the same venue (see SQL above)
- Auto-add them to `tagged_user_ids` on the post
- Only tag users in the poster's network (friendships check)

## What changes in existing code

### DB RPCs to modify:
- **`leader_complete_venue_lockout`** — repurpose or remove. For venue lockouts, each user calls `complete_venue_lockout` on their own session. The "leader ends all" behavior only applies to timed lockouts.
- **`join_lockout_session`** — skip for venue lockouts. The "join" flow creates a new session instead.
- **New RPC: `get_venue_companions`** — returns friends at the same venue with overlapping sessions.
- **New RPC: `notify_venue_departure`** — sends push notification to friends at the same venue when someone taps out.

### Dart changes:
- **`friends_locked_out_list.dart`** — "Join" on venue lockout calls `startVenueLockout(venue)` instead of `joinSession(sessionId)`
- **`manual_lockout_view.dart`** — tap-out calls `complete_venue_lockout` (own session only), triggers departure notification. Show co-located friends on lockout screen.
- **`manual_lockout_notifier_provider.dart`** — remove venue-specific logic from `joinLockout` (venue "joins" use `startVenueLockout` instead)
- **`use_post_creation.dart`** — for venue lockout posts, query `get_venue_companions` and auto-tag

### What stays the same:
- Timed lockout join flow (participants array, leader ends all)
- NFC scanning mechanics (GoBackNfcPlugin, NfcService)
- Venue upsert on first scan
- `completed_at` lifecycle for both lockout types
- Stats tracking (`lockout_completed_log`, `weekly_lockout_minutes`)
- 10-minute minimum for venue lockout posts

## Edge cases

- **User already locked out elsewhere:** Prevent starting a second lockout (existing check). They must end their current lockout first.
- **App killed during venue lockout:** On resume, check if session still exists in DB. If auto-deleted (10-day cleanup), clear local storage.
- **No friends at venue:** Lockout works as solo — no companions shown, no auto-tagging.
- **Friend leaves and re-joins:** They get a new session. Both sessions are valid — the overlap query handles this.
