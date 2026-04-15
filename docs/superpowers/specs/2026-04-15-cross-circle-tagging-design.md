# Cross-Circle Tagging & Lockout Visibility Redesign

**Date:** 2026-04-15
**Status:** Draft — pending user review

## Problem

Circle sizes are limited (max 150) and asymmetric — my circle is not my friend's circle. When I join my friend's lockout and their other friend (not in my circle) also joins, the current system has undefined behavior for: tagging, post visibility, profile access, comments, reactions, and notifications across circle boundaries.

Additionally, the goback score is currently stored per-session (one score shared by all participants), which is a bug — each participant's score should reflect their own device signals.

## Approach: Lockout-Level Visibility (B-Derived)

Instead of writing N participant tags per post (O(N²) across a lockout), visibility is derived from lockout membership. A new `lockout_participants` table tracks who was in each lockout, how they got there, and their individual score.

- `post_tags` = manual @mentions only (circle-only)
- `lockout_participants` = who was in the lockout, join chain, individual scoring
- Feed visibility = friendship OR shared lockout membership
- Distance computed client-side from `joined_via` + local friend list

---

## 1. Data Model

### New table: `lockout_participants`

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | UUID | NO | PK |
| session_id | UUID | NO | FK → lockout_sessions, ON DELETE CASCADE |
| user_id | UUID | NO | FK → profiles |
| joined_via | UUID | YES | FK → profiles. NULL for owner and direct friends of owner |
| joined_at | TIMESTAMPTZ | NO | When they joined |
| left_at | TIMESTAMPTZ | YES | Set on early leave; participant still shows on posts |
| goback_score | SMALLINT | YES | Individual score (0-100), null if lockout too short |
| battery_was_charging | BOOLEAN | YES | Whether charging detected during this user's lockout |
| step_count | SMALLINT | YES | Steps recorded on this user's device |

**Indexes:**
- `(session_id, user_id)` UNIQUE — prevents double joins
- `(user_id)` — for feed visibility and active lockout checks

**Owner gets a row** at session creation. `joined_via = NULL`, `joined_at = started_at`.

**Dual-write contract:** `join_lockout_session()` does both `array_append` on `lockout_sessions.participants` and `INSERT INTO lockout_participants` in the same transaction. The array remains the authorization source of truth for existing RPCs. The table is the source of truth for join chain and scoring.

### Per-participant scoring

The goback score (0-100) measures how mentally disconnected a user was during a lockout. Each participant gets their own score computed on their device from their own sensor data.

**Score signals (all captured client-side):**
- Battery drain (batteryStart → batteryEnd): less drain = phone idle = higher score
- Charging state: if charging detected, battery data unreliable — formula shifts weight to steps
- Step count: one-way boost only. Steps prove disconnection. Zero steps is neutral.

**Formula:**
```
timeMultiplier = 0.7 + 0.3 * (minutes / 240).clamp(0, 1)  // 0.7x at 0 min → 1.0x at 4 hrs
stepBonus = 0.3 * (stepsPerHour / 3000).clamp(0, 1)        // 0.0–0.3 boost

Case 1 (battery reliable, no charging): quality = batteryQuality + stepBonus, capped at 1.0
Case 2 (was charging, has steps):       quality = 0.7 + stepBonus, capped at 1.0
Case 2b (was charging, no steps):       quality = batteryQuality, capped at 0.7
Case 3 (no battery data):              quality = 0.7 + stepBonus, capped at 1.0

score = (quality * 100 * timeMultiplier).round().clamp(0, 100)
```

Full implementation: `lib/core/features/lockout/domain/utilities/goback_score_calculator.dart`

**`update_lockout_score()` RPC — scoped to caller's own row:**
```sql
UPDATE lockout_participants
SET goback_score = LEAST(100, GREATEST(0, p_score)),
    battery_was_charging = p_battery_was_charging,
    step_count = CASE WHEN p_step_count IS NOT NULL
                      THEN LEAST(32767, GREATEST(0, p_step_count))
                      ELSE NULL END
WHERE session_id = p_session_id AND user_id = auth.uid();
```

**Score reads:**
- Feed/post RPCs: join `lockout_participants ON session_id = post.lockout_id AND user_id = post.author_id` — shows that author's individual score
- Stats RPCs: filter `lockout_participants` by requesting user's ID
- `lockout_completed_log`: sources score from the participant row for the completing user

**Superseded columns:** `lockout_sessions.goback_score`, `.battery_was_charging`, `.step_count` — RPCs stop writing to them. Can be dropped or left for historical data.

### Unchanged

- `lockout_sessions.participants` UUID array — kept for all existing RPCs
- `post_tags` table structure — now used only for manual @mentions
- `battery_at_start` — tracked client-side in `ManualLockoutStorable`, not stored server-side

---

## 2. Chain Joining

**Current:** `join_lockout_session()` checks friendship with session owner only.

**New:** Checks friendship with any current participant (owner or anyone in the participants array).

```sql
-- Find a friend who is already in the lockout
SELECT friend_id INTO v_joined_via
FROM (
  SELECT ls.user_id AS friend_id FROM lockout_sessions ls
  WHERE ls.id = p_lockout_id
  UNION
  SELECT unnest(ls.participants) AS friend_id FROM lockout_sessions ls
  WHERE ls.id = p_lockout_id
) candidates
WHERE EXISTS (
  SELECT 1 FROM friendships f
  WHERE (f.user_a_id = v_user_id AND f.user_b_id = candidates.friend_id)
     OR (f.user_b_id = v_user_id AND f.user_a_id = candidates.friend_id)
)
LIMIT 1;

IF v_joined_via IS NULL THEN
  RETURN 'You must be friends with someone in this lockout';
END IF;
```

Then dual-write:
```sql
UPDATE lockout_sessions SET participants = array_append(participants, v_user_id) WHERE id = p_lockout_id;
INSERT INTO lockout_participants (session_id, user_id, joined_via, joined_at)
VALUES (p_lockout_id, v_user_id, v_joined_via, NOW());
```

**`joined_via` is NULL when:** the joiner is a direct friend of the owner.

**Notifications on join:**
- Owner gets notified (existing behavior)
- The `joined_via` user also gets notified: "C joined the lockout through you"

**How users join:** By seeing their friend is locked out in the friends-locked-out list and tapping join. No explicit invite needed. The chain extends naturally — A joins B's lockout, C sees A is locked out and joins.

**Leaving doesn't cascade:** If A leaves, C stays in the lockout. C's `joined_via` still points to A (historical record).

**Early leavers still get auto-tagged:** Leaving a lockout doesn't erase participation from others' posts.

---

## 3. Feed Visibility

**Current:** Posts from yourself + friends, within 24h, excluding `excluded_user_ids`.

**New:** Same, plus posts from any lockout you participated in.

```sql
WHERE p.published_at > NOW() - INTERVAL '24 hours'
  AND NOT (v_user_id = ANY(p.excluded_user_ids))
  AND (
    p.author_id = v_user_id
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE (f.user_a_id = v_user_id AND f.user_b_id = p.author_id)
         OR (f.user_b_id = v_user_id AND f.user_a_id = p.author_id)
    )
    OR (
      p.lockout_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM lockout_participants lp
        WHERE lp.session_id = p.lockout_id AND lp.user_id = v_user_id
      )
    )
  )
```

**Score on feed posts:** Changes from `lockout_sessions.goback_score` to:
```sql
LEFT JOIN lockout_participants lp_author
  ON p.lockout_id = lp_author.session_id AND lp_author.user_id = p.author_id
...
lp_author.goback_score AS lockout_score
```

**Cross-circle posts in the feed:**
- Mixed with regular posts, sorted by `published_at`
- Client detects cross-circle: `is_author_connected = false AND lockout_id IS NOT NULL`
- Client can show a "from a shared lockout" indicator

**24-hour expiry is automatic** — `published_at > NOW() - 24h` handles it. No cleanup needed.

**Exclusion:** Lockout participants can't be excluded (enforced at post creation). The exclusion check stays in the query but `excluded_user_ids` won't contain lockout participants.

---

## 4. Post Detail & Participant Display

### Visibility

`get_post_by_id()` gets the same lockout-based OR condition as the feed query.

### Returns two separate lists

**Manual mentions** (from `post_tags`, unchanged):
```sql
tagged_user_ids, tagged_usernames, tag_types
```

**Lockout participants** (new, from `lockout_participants`):
```sql
SELECT lp.user_id, lp.joined_via, prof.username, prof.avatar_url
FROM lockout_participants lp
JOIN profiles prof ON lp.user_id = prof.id
WHERE lp.session_id = p.lockout_id AND lp.user_id != p.author_id
```

**Score** reads from `lockout_participants` for the post author.

### Client-side distance computation

Client has local friend list + `joined_via` from the response:

```dart
int getDistance(String participantId, String? joinedVia, Set<String> myFriends) {
  if (myFriends.contains(participantId)) return 1;
  if (joinedVia != null && myFriends.contains(joinedVia)) return 2;
  return 3;
}
```

### Display tiers

- **Distance 1:** `@username` — tappable, navigates to full profile
- **Distance 2:** `@username · friend of @X` — tappable, navigates to limited profile (avatar, username, add to circle)
- **Distance 3+:** collapsed as "and N others" — not tappable, no profile access

---

## 5. Comments & Reactions

### Per-viewer comment filtering

`get_post_comments()` filters by viewer's circle + post author:

```sql
WITH my_friends AS (
  SELECT CASE WHEN f.user_a_id = v_user_id THEN f.user_b_id ELSE f.user_a_id END AS friend_id
  FROM friendships f
  WHERE f.user_a_id = v_user_id OR f.user_b_id = v_user_id
)
SELECT pc.id, pc.author_id, prof.username, prof.avatar_url, pc.content, pc.created_at, pc.deleted_at
FROM post_comments pc
JOIN profiles prof ON pc.author_id = prof.id
WHERE pc.post_id = p_post_id
  AND (
    pc.author_id = v_user_id
    OR pc.author_id = v_post_author_id
    OR pc.author_id IN (SELECT friend_id FROM my_friends)
  )
ORDER BY pc.created_at ASC;
```

The `my_friends` CTE runs once (max 150 rows), then filters with `IN`.

The visibility check at the top of `get_post_comments()` also needs the lockout-based OR condition so cross-circle users can load comments.

### Filtered comment count

Comment count becomes per-viewer computed (not the denormalized `posts.comment_count`):

```sql
(SELECT COUNT(*) FROM post_comments pc
 WHERE pc.post_id = p.id AND pc.deleted_at IS NULL
   AND (
     pc.author_id = v_user_id
     OR pc.author_id = p.author_id
     OR EXISTS (
       SELECT 1 FROM friendships f
       WHERE (f.user_a_id = v_user_id AND f.user_b_id = pc.author_id)
          OR (f.user_b_id = v_user_id AND f.user_a_id = pc.author_id)
     )
   )
) AS comment_count
```

Applied in both `get_user_feed()` and `get_post_by_id()`. The denormalized `posts.comment_count` column stays for internal use but is no longer used for display.

### Reactions and comments — cross-circle restrictions

- **Commenting:** Cross-circle users CANNOT comment. Existing INSERT RLS (friendship with author required) enforces this.
- **Reacting:** Cross-circle users CANNOT react. Existing INSERT RLS enforces this.
- **Viewing reactions:** Reaction count stays global (no privacy concern — just emoji counts).

---

## 6. Notifications

### Lockout post notifications (replaces auto-tag notifications)

Since participants are no longer written to `post_tags`, the existing `trigger_notification_on_tag()` only fires for manual @mentions (circle-only, distance 1).

New notification logic runs after lockout post creation:

```sql
FOR v_participant IN
  SELECT lp.user_id, lp.joined_via
  FROM lockout_participants lp
  WHERE lp.session_id = p_lockout_id AND lp.user_id != v_author_id
LOOP
  IF is_friend(v_author_id, v_participant.user_id) THEN
    -- Distance 1: standard tag notification
    PERFORM upsert_notification(v_participant.user_id, 'tag', p_post_id, v_author_id);
  ELSIF is_friend(v_author_id, v_participant.joined_via) THEN
    -- Distance 2: contextual notification
    PERFORM upsert_notification(v_participant.user_id, 'lockout_tag', p_post_id, v_author_id);
  END IF;
  -- Distance 3+: no notification
END LOOP;
```

### Notification types

- `tag` (existing) — "B tagged you in a post" — distance 1 (friends)
- `lockout_tag` (new) — "A friend of [X] tagged you in a lockout post" — distance 2 (friend of friend)

Push notifications follow the same distance filtering. Distance 2 push includes the mutual friend's name.

### Connection request context

`connection_requests` table gets two new nullable columns:
- `context_type` TEXT — e.g. `'shared_lockout'`
- `context_id` UUID — the lockout session ID

Displayed to receiver: "B wants to connect — you were in a lockout together"

`send_connection_request` RPC gets optional `p_context_type` and `p_context_id` params.

### Notification cleanup

`lockout_tag` notifications removed after 24 hours — either via pg_cron job or by filtering in the notification fetch query: `WHERE type != 'lockout_tag' OR created_at > NOW() - INTERVAL '24 hours'`.

---

## 7. Friends Locked Out Display

### After joining: see all participants

`get_friends_locked_out()` Part 3 (co-participants in lockouts I joined) currently filters by friendship. That filter is removed after joining:

```sql
-- Part 3 (revised): ALL co-participants in lockouts I JOINED
SELECT
  joined_ls.id AS lockout_id,
  co_participant AS user_id,
  prof.username,
  prof.avatar_url,
  joined_ls.started_at,
  joined_ls.ends_at,
  joined_ls.action_text,
  joined_ls.location_lat,
  joined_ls.location_lng,
  joined_ls.location_name,
  joined_ls.participants,
  lp.joined_via
FROM lockout_sessions joined_ls
CROSS JOIN LATERAL unnest(joined_ls.participants) AS co_participant
JOIN profiles prof ON co_participant = prof.id
LEFT JOIN lockout_participants lp ON lp.session_id = joined_ls.id AND lp.user_id = co_participant
WHERE
  v_user_id = ANY(joined_ls.participants)
  AND co_participant != v_user_id
  AND (joined_ls.is_open_ended OR joined_ls.ends_at > NOW())
  AND joined_ls.post_id IS NULL
  AND joined_ls.completed_at IS NULL
```

**Before joining (Parts 1 & 2):** No change — you only see your direct friends' lockouts.

**Return type:** Gains `joined_via UUID` column for client-side distance computation.

**Display tiers (same as post detail):**
- Distance 1: `@username`
- Distance 2: `@username · friend of @X`
- Distance 3+: collapsed as "and N others"

---

## 8. Post Creation Flow

### Stop writing participant tags

`use_post_creation.dart` (lines 131-171) currently auto-tags all lockout participants into `post_tags`. This is removed. Only manual @mentions from the description are written to `post_tags`.

The `lockout_id` on the post is sufficient — participant display is derived from `lockout_participants` at read time.

### Exclusion enforcement

Lockout participants cannot be excluded from the post (enforced at app level). Cross-circle participants don't appear in the visibility selection list (they're not in the user's circle), so no UI change needed — it just works.

### Deprecated

`PostCrudService.addParticipantTags()` — no longer called. Can be removed.

### Post-creation notification

After creating a lockout post, trigger the notification logic from Section 6 to notify lockout participants based on distance.

---

## 9. Profile Access & Connection Requests

### Three tiers based on distance

| Distance | Tap behavior | Profile content | Actions |
|----------|-------------|-----------------|---------|
| 1 (friend) | Full profile | Everything — posts, calendar, bio | All existing |
| 2 (friend of friend) | Limited profile | Username, avatar only | "Add to circle" button |
| 3+ | Not tappable | N/A | N/A |

### Limited profile view

New lightweight screen showing only:
- Avatar (large)
- Username
- "Add to circle" button
- No posts, no calendar, no bio

### Connection request with context

When sending a request from the limited profile (shared lockout context):

```dart
sendConnectionRequest(
  receiverId: userId,
  contextType: 'shared_lockout',
  contextId: lockoutSessionId,
)
```

Receiver sees: "B wants to connect — you were in a lockout together"

---

## 10. Share Card & Calendar

### Share card

When post has a `lockout_id`: display "Locked out with N others" (N = participant count minus author). No usernames, no relationship labels.

Posts without `lockout_id`: show manual @mention usernames as before.

### Calendar

Cross-circle posts do NOT appear on the viewer's calendar. No changes needed — calendar queries are friendship-based and don't get the lockout visibility OR condition.

---

## 11. RLS Policy Summary

### New policies

| Table | Policy | Rule |
|-------|--------|------|
| `posts` SELECT | "Users can view lockout posts they participated in" | `lockout_id IS NOT NULL AND EXISTS (lockout_participants WHERE session_id = lockout_id AND user_id = auth.uid())` |
| `post_media` SELECT | "Media viewable via lockout participation" | Same lockout_participants check |
| `lockout_participants` SELECT | "Users can read participants for accessible sessions" | `user_id = auth.uid() OR EXISTS (friendship with session owner) OR EXISTS (own row in same session)` |
| `lockout_participants` INSERT | "Users can only insert own rows" | `user_id = auth.uid()` (in practice bypassed by SECURITY DEFINER RPCs) |
| `lockout_participants` UPDATE | "Users can only update own rows" | `user_id = auth.uid()` |

### Unchanged policies (confirmed no modification)

| Table | Policy | Reason |
|-------|--------|--------|
| `posts` INSERT/UPDATE/DELETE | Author-only | Cross-circle users don't create/edit others' posts |
| `post_comments` INSERT | Friendship with author | Cross-circle users can't comment |
| `post_reactions` INSERT | Friendship with author | Cross-circle users can't react |
| `post_tags` SELECT/INSERT | Friendship-based | Now mentions-only, always circle-based |
| `lockout_sessions` | `ANY(participants)` | Array kept, policies untouched |

**Key principle:** Lockout-based visibility is additive. New SELECT policies alongside existing ones. No existing policies modified or removed.

---

## Design Decisions Reference

| # | Question | Decision |
|---|----------|----------|
| 1 | Who can join a lockout? | Chain joining (friend of any participant) — no open venue joining |
| 2 | How does someone chain-join? | Self-join by seeing friend is locked out |
| 3 | Which session do chain-joiners join? | The owner's original session |
| 4 | Post authorship | Each participant creates their own post independently |
| 5 | Auto-tagging scope | All participants auto-tagged; non-friends shown as "friend of X" |
| 6 | Cross-circle profile access | Limited profile: username, avatar, add to circle |
| 7 | Can non-friends see tagged posts? | Yes — lockout participation grants read-only visibility |
| 8 | Manual @mentions | Circle-only. Non-friends don't appear in autocomplete |
| 9 | Comment @mentions | Circle-only. Same rule as post mentions |
| 10 | Cross-circle comment visibility | Only see comments from your circle + post author |
| 11 | Notifications | Distance 2 only, with "friend of X" context. Distance 3+ no notification |
| 12 | Distance 3+ display | Collapsed as "and N others", anonymous, no profile access |
| 13 | Participant list during lockout | All visible after joining, with distance tiers |
| 14 | Leaving cascades? | No — leaving doesn't remove chain-joined participants |
| 15 | Join chain tracking | `joined_via` per participant (who was the link) |
| 16 | Cross-circle posts in feed | Yes, mixed in regular feed with "shared lockout" indicator |
| 17 | Cross-circle reactions/comments | View only — can't react or comment |
| 18 | Comment count | Filtered per viewer (not global count) |
| 19 | Exclusion of lockout participants | Not allowed — lockout participants can't be excluded |
| 20 | Tag display order | Distance 1 first, then "friend of X", then collapsed "and N others" |
| 21 | "Friend of X" label source | Uses `joined_via` field (who they actually joined through) |
| 22 | Share card | "Locked out with N others" — no usernames |
| 23 | Calendar | Cross-circle posts don't appear |
| 24 | Connection request context | "You were in a lockout together" when from shared lockout |
| 25 | Tag visibility duration | Expires with 24-hour feed window |
| 26 | Expired notifications | Removed after 24 hours |
