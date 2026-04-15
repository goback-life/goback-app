# Circle Leaderboard — King of the Mountain

## Overview

Replace the alphabetical friend list on the Circle page with a leaderboard ranked by average lockout duration over a rolling 7-day window. The list is inverted — #1 sits at the bottom of the scroll (the "peak"), and users scroll up to see lower-ranked friends.

## Visual Design

### Tile Layout

Minimal rows directly on `#1A1A1A` — no card borders, no backgrounds. Matches the existing friend tile aesthetic exactly.

| Property | Value |
|----------|-------|
| Height | 59px (66px for king) |
| Left indent | 10% screen width |
| Right margin | 10% screen width |
| Avatar size | 39px (42px for king) |
| Avatar-to-text spacing | 10px |
| Font | Quicksand |
| Username size | 24px, weight 500 |
| Username letter spacing | -1.44px |
| Duration size | 14px, weight 500 |
| Duration position | Right-aligned where chevron currently sits |
| Rank number position | Left of avatar, right-aligned in 28px-wide column |

### Tile Variants

**Regular tile:**
- Rank number: `white @ 0.25 opacity`, 13px, weight 500
- Username: `white`, 24px, weight 500
- Duration: `white @ 0.5 opacity`, 14px, weight 500

**Current user tile:**
- Left accent bar: 3px wide, 28px tall, `#598EB5 @ 0.6 opacity`, vertically centered, positioned at `10% - 14px`
- Username: `#598EB5`, 24px, weight 600
- Duration: `#598EB5 @ 0.7 opacity`, 14px, weight 500

**King (#1) tile:**
- Left accent bar: 3px wide, 32px tall, `gold (#FFD700) @ 0.5 opacity`
- Crown icon (♔) replaces rank number: `gold @ 0.5 opacity`, 14px, weight 600
- Avatar: 42px (slightly larger)
- Username: `gold (#FFD700) @ 0.75 opacity`, 24px, weight 600
- Duration: `gold @ 0.6 opacity`, 14px, weight 600
- Tile height: 66px

**Inactive tile (0 sessions in 7 days):**
- Username: `white @ 0.4 opacity`, 24px, weight 500
- Avatar background: `#598EB5 @ 0.3 opacity`
- Duration: replaced with em dash `—` in `white @ 0.25 opacity`
- Sublabel: "no sessions" in `white @ 0.2 opacity`, 10px

### Scroll Behavior

- ListView uses `reverse: true` (same as current implementation)
- Page loads scrolled to the bottom — #1 (King) is visible first
- Scrolling up reveals lower-ranked friends
- Inactive friends (0 sessions) appear at the top of the scroll (furthest from peak)

### Existing Elements Retained

- Circle/Requests tab toggle at top — unchanged
- Search pill at bottom — unchanged, filters leaderboard by username
- Add menu (plus button) — unchanged
- Remove mode — unchanged
- Swipe-to-delete — unchanged

## Ranking Logic

- **Primary sort:** Average lockout duration over rolling 7 days, descending
- **Tiebreaker:** Alphabetical by username
- **Scope:** All circle members + the current user
- **Inactive handling:** Friends with 0 sessions in 7 days sort to the bottom (top of scroll) with duration displayed as `—`
- **Current user:** Always included in the list, highlighted with accent-blue treatment

## Data Layer

### Supabase RPC Function

New database function `get_circle_leaderboard(p_user_id UUID)` that:

1. Finds all circle members for the given user (via friendships/connections table)
2. Joins `lockout_participants` filtered to `joined_at >= now() - interval '7 days'`
3. Computes per-member:
   - `avg_duration_minutes`: average lockout duration in minutes (from `joined_at` to `left_at`, or `joined_at` to `now()` if still active)
   - `session_count`: number of sessions in the window
4. Returns all circle members (including those with 0 sessions) sorted by `avg_duration_minutes DESC NULLS LAST`, then `username ASC`
5. Includes the current user in the result set

**Performance:**
- Add index on `lockout_participants(user_id, joined_at)` if not already present
- Query is bounded by circle size (max 150 members) x sessions per member in 7 days (single digits)
- Each user's call touches only their circle — scales horizontally with user count

### Migration

New migration file containing:
- The `get_circle_leaderboard` RPC function
- Index on `lockout_participants(user_id, joined_at)` (if missing)

### Flutter Provider

New auto-dispose Riverpod provider `getCircleLeaderboardProvider` that:
- Calls the RPC function with the current user's ID
- Returns `Result<List<LeaderboardEntryModel>>`
- Sets `AsyncValue.loading()` on fetch, catches errors with `(error, stackTrace)`

### Model

New Freezed model `LeaderboardEntryModel`:
- `userId: String`
- `username: String`
- `avatarUrl: String?`
- `avgDurationMinutes: double?` (null = no sessions)
- `sessionCount: int`
- `isCurrentUser: bool`
- `rank: int`

## What This Does NOT Include

- Score display on tiles (kept clean; could be added on tap/detail later)
- Animated transitions between rank changes
- Time period toggle (fixed at rolling 7 days)
- Push notifications for rank changes
