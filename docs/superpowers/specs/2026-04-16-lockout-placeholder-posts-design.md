# Lockout Placeholder Posts

**Date:** 2026-04-16
**Status:** Approved

## Problem

Lockout notifications are not engaging enough. When user A locks out, user B sees a notification and must navigate to the notifications page to act on it. We want lockouts to surface directly in the feed as joinable cards.

## Solution

When someone locks out, a placeholder card appears in their friends' feeds — rendered directly from `lockout_sessions` data (no rows in the `posts` table). The card shows the goback logo, lockout duration/time remaining, activity, and location, with a "Join Lockout" button. When the lockout ends, the card disappears naturally.

## Design Decisions

- **No post table bloat**: Placeholder cards are rendered from `lockout_sessions` data, not real post rows.
- **Client-side merge**: Active friend lockouts (via existing `getFriendsLockedOut` provider) are merged into the feed list client-side. No DB/RPC changes needed.
- **Chronological sorting**: Placeholders are sorted alongside real posts by `startedAt`, not pinned to the top.
- **24h feed filter still applies**: Long lockouts may age out of the feed. Accepted trade-off for simplicity.
- **Natural disappearance**: `getFriendsLockedOut` only returns sessions with `completed_at IS NULL`, so completed lockouts drop out on feed refresh.
- **Existing join flow**: The join button triggers the same join dialog and `joinLockout` flow already in place.

## Data Layer

No new tables or migrations.

**Data source**: Existing `getFriendsLockedOut` RPC returning `LockoutSessionModel` with fields: `id`, `userId`, `startedAt`, `endsAt`, `isOpenEnded`, `actionText`, `locationName`, `username`, `avatarUrl`.

**Unified feed item**: A Freezed sealed class that wraps either a `FeedPostModel` or a `LockoutSessionModel`:

```dart
@freezed
sealed class FeedItem with _$FeedItem {
  const factory FeedItem.post(FeedPostModel post) = FeedItemPost;
  const factory FeedItem.lockoutPlaceholder(LockoutSessionModel lockout) = FeedItemLockoutPlaceholder;
}
```

The feed list type changes from `List<FeedPostModel>` to `List<FeedItem>`.

## Feed Merge Logic

1. Fetch real posts via `get_user_feed` as usual.
2. Fetch active friend lockouts via existing `getFriendsLockedOut` provider.
3. Filter out lockout sessions where the current user is the owner or already a participant (no self-placeholders, no duplicate join prompts).
4. Wrap both into `FeedItem` union types.
5. Merge and sort by timestamp (`publishedAt` for posts, `startedAt` for lockouts).
6. Render the merged list.

Lockout items do not participate in cursor-based pagination — they are always fetched in full (typically 0-5 items) and inserted chronologically into the merged list.

On feed refresh, completed lockouts naturally drop out since `getFriendsLockedOut` only returns active sessions.

## UI — Placeholder Card

Layout mirrors a regular post card:

- **Top**: User avatar + username (from lockout session data).
- **Media area**: Goback logo asset, centered.
- **Info section**:
  - **Timed lockouts**: Time remaining, counting down live.
  - **Open-ended/venue lockouts**: Elapsed time, counting up live.
  - Activity text (`actionText`).
  - Location/venue name (`locationName`).
- **Bottom**: "Join Lockout" button — triggers existing join dialog and `joinLockout` flow.

No reactions, comments, or share functionality on placeholder cards.

The countdown/elapsed timer updates live via a timer widget.

## What This Feature Does NOT Change

- Post creation flow (unchanged).
- Post table schema (unchanged).
- Feed RPC `get_user_feed` (unchanged).
- Lockout completion flow — skip deletes session, share creates a real post (unchanged).
- Notification system (unchanged, still sends push notifications alongside this).
- RLS policies (unchanged).

## Edge Cases

- **User is the lockout owner**: Their own lockout does not appear as a placeholder in their own feed.
- **User already joined**: Lockouts the user has already joined are filtered out (no duplicate join prompts).
- **Lockout ends while viewing feed**: Card remains until next feed refresh, then disappears. The join button should handle the case where the session is no longer active (show an error/toast).
- **Multiple friends locked out**: Multiple placeholder cards appear, each sorted chronologically.
- **24h expiry**: A lockout that started >24h ago may be filtered out by the feed's 24h rule. Accepted.
