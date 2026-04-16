# Circle Hub Button — Design Spec

## Summary

Replace the separate Circle and Notifications nav bar icons with a single glass circle button on FeedView. Tapping it opens a new CircleHubPage with three tabs: Lockouts, Circle, and Notifications. The Circle tab's search is unified to find both circle members and non-circle users in one search bar.

## FeedView — Glass Circle Button (`FeedCircleHubButton`)

- **Position**: `Positioned` in FeedView's stack, top-right. Same vertical offset as `FeedDateOverlay` (`safeTop + 8 * s`), right-aligned with ~16px scaled margin.
- **Appearance**: Plain glass circle, ~32px diameter (scaled). `AppGlassContainer` with `GlassVariant.clear` and accent tint — same color/feel as the lockout triangle button.
- **No icon inside** — just the glass circle.
- **Red state**: When unread notifications OR pending friend requests exist, the glass tint switches to `MainColors.red500.withValues(alpha: 0.35)` — same approach as `FeedDateOverlay`.
- **Tap action**: `router.push(const CircleHubRoutable())`.

## CircleHubPage

New page at `lib/presentation/pages/circle_hub/`.

### Files

- `circle_hub_page.dart` — Scaffold with `AppGlassLayer`, `IndexedStack` of 3 views, glass tab toggle at top.
- `circle_hub_routable.dart` — Freezed routable, registered in `routes.dart`.

### Tab Toggle

3-pill glass toggle at top, same style as `YourCirclePage`'s existing 2-pill toggle extended to 3 pills. Uses `GlassVariant.clear` with accent tint. Selected pill gets accent tint background (0.25 opacity).

Tab order: **Lockouts** (index 0, default) | **Circle** (index 1) | **Notifications** (index 2).

### Tab Views

- **Lockouts (index 0)**: Reuses existing `FriendsLockedOut` view content. No layout changes.
- **Circle (index 1)**: Reuses existing `YourCircleView` layout (leaderboard, bottom search bar, etc.). Only behavioral change: search queries both circle members AND non-circle users. Circle members show rank/stats. Non-circle users show "Send request" button.
- **Notifications (index 2)**: Reuses existing `NotificationsView`. Already handles friend request accept/deny. Same filtering (excludes `lockoutStarted` and `lockoutJoined`). No layout changes.

## Unified Circle Search

The Circle tab's bottom search bar (currently filters circle members only) becomes a unified search:

- **When not searching**: Member leaderboard (unchanged).
- **When searching**: Results show both circle members and non-circle users. Circle members display with rank/stats (existing tile). Non-circle users display with "Send request" button (existing tile from `ConnectionRequestsView`). Reuses existing `SearchUsers` provider for non-circle results and filters local circle list for member matches.

## Removed: Requests Tab

The separate "Requests" tab in `YourCirclePage` is removed. Its two functions are redistributed:
- **User search for adding friends** → merged into Circle tab search.
- **Incoming friend request accept/deny** → already present in Notifications tab.

## HomeNavigationBar Changes

Remove the Circle icon and Notifications icon from `HomeNavigationBar` (if HomePage is still used). Profile, logo, and friends-locked-out icons remain unchanged.

## What Does NOT Change

- Layout/design of FriendsLockedOut view.
- Layout/design of Circle view (bottom search bar, leaderboard, member tiles, etc.).
- Layout/design of Notifications view.
- `FeedDateOverlay`, `FeedLockoutButton`.
- All providers, services, and data layers remain the same.
