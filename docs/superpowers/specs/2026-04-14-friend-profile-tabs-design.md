# Friend Profile Stats & Hobbies Tabs

**Date:** 2026-04-14
**Status:** Approved

## Summary

Add the same 3-tab layout (Calendar / Stats / Hobbies) to the friend profile page (`CircleProfileView`) so users can view a friend's detailed stats and hobby breakdown, matching the structure of their own profile.

## Current State

`CircleProfileView` shows:
- Avatar, username, bio (same positioning as own profile)
- `ProfileWeeklyStats` — single-line weekly lockout minutes summary
- `ProfileCalendar` — read-only calendar of friend's lockout sessions

`ProfileView` (own profile) shows:
- Avatar, username, bio
- `ProfileTabToggle` — Calendar / Stats / Hobbies tabs
- `IndexedStack` with `ProfileCalendar`, `ProfileStatsView`, `ActivityBubbleCloud`

## Change

Replace the `ProfileWeeklyStats` + standalone calendar in `CircleProfileView` with the tab toggle + indexed stack pattern from `ProfileView`.

### File: `lib/presentation/pages/circle_profile/views/circle_profile_view.dart`

1. Add imports for `ProfileTabToggle`, `ProfileStatsView`, `ActivityBubbleCloud`
2. Remove import for `ProfileWeeklyStats`
3. Add `tabIndex` state via `useState<int>(0)`
4. Replace the `ProfileWeeklyStats` Positioned widget with `ProfileTabToggle`
5. Replace the standalone `ProfileCalendar` Positioned widget with an `IndexedStack` containing:
   - Tab 0: `ProfileCalendar(userId: userId, scale: s)`
   - Tab 1: `ProfileStatsView(userId: userId, scale: s, username: profileToUse?.username ?? '')`
   - Tab 2: `ActivityBubbleCloud(userId: userId, scale: s)`

### No changes needed

- **Backend:** `getLockoutDailyStatsProvider` and `getLockoutActivityStatsProvider` already accept a `userId` parameter and work for any user
- **RLS:** No new table access — same lockout stats queries
- **Components:** `ProfileTabToggle`, `ProfileStatsView`, `ActivityBubbleCloud` are already parameterized by userId and reusable
- **Navigation/routing:** No changes

## Privacy

No privacy controls. All connections can see all stats and hobbies.

## Scope

Single file change, ~20 lines modified. No new files, no backend changes.
