# Lockout Placeholder Posts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show active friend lockout sessions as placeholder cards in the feed, with a join button, rendered from `lockout_sessions` data (no post table rows).

**Architecture:** Client-side merge approach. A `FeedItem` sealed class wraps either a `FeedPostModel` or a `LockoutSessionModel`. The `useFeedPosts` hook watches the existing `friendsLockedOutCacheProvider`, filters out self/already-joined, wraps into `FeedItem`, merges with posts, and sorts chronologically. A new `LockoutPlaceholderCard` widget renders lockout items in the feed. No DB changes.

**Tech Stack:** Flutter, Riverpod, Freezed (existing models only), existing `FriendsLockedOutCache` provider.

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `lib/core/features/post/domain/models/feed_item.dart` | Sealed class: `FeedItemPost` or `FeedItemLockoutPlaceholder` |
| Create | `lib/presentation/pages/feed/components/lockout_placeholder_card.dart` | UI card for lockout placeholders in feed |
| Modify | `lib/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart` | Merge lockouts into feed, change return type to `List<FeedItem>` |
| Modify | `lib/presentation/pages/feed/components/feed_posts_list.dart` | Accept `List<FeedItem>`, dispatch to correct card widget |
| Modify | `lib/presentation/pages/feed/views/feed_view.dart` | Adapt callbacks and types for `FeedItem` |

---

### Task 1: Create `FeedItem` sealed class

**Files:**
- Create: `lib/core/features/post/domain/models/feed_item.dart`

This is a plain Dart sealed class (no Freezed/codegen needed). Provides a `sortTimestamp` getter used for chronological sorting in the feed.

- [ ] **Step 1: Create the FeedItem sealed class**

```dart
// lib/core/features/post/domain/models/feed_item.dart
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';

/// A unified feed item that can be either a post or a lockout placeholder.
///
/// Lockout placeholders are rendered from active friend lockout sessions
/// (no rows in the posts table). They appear chronologically alongside
/// real posts and disappear when the lockout ends.
sealed class FeedItem {
  const FeedItem();

  /// Timestamp used for chronological sorting in the feed.
  DateTime get sortTimestamp;

  /// Unique key for use in list widgets.
  String get itemKey;
}

class FeedItemPost extends FeedItem {
  const FeedItemPost(this.post);
  final FeedPostModel post;

  @override
  DateTime get sortTimestamp => post.createdAt;

  @override
  String get itemKey => 'post_${post.id}';
}

class FeedItemLockoutPlaceholder extends FeedItem {
  const FeedItemLockoutPlaceholder(this.lockout);
  final LockoutSessionModel lockout;

  @override
  DateTime get sortTimestamp => lockout.startedAt;

  @override
  String get itemKey => 'lockout_${lockout.id}';
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter analyze lib/core/features/post/domain/models/feed_item.dart`
Expected: No errors for this file.

- [ ] **Step 3: Commit**

```bash
git add lib/core/features/post/domain/models/feed_item.dart
git commit -m "feat: add FeedItem sealed class for unified feed items"
```

---

### Task 2: Create `LockoutPlaceholderCard` widget

**Files:**
- Create: `lib/presentation/pages/feed/components/lockout_placeholder_card.dart`

Mirrors `FeedPostCard` layout (squircle area at top, author row below) but replaces the image with the goback logo and adds lockout info + join button.

- [ ] **Step 1: Create the LockoutPlaceholderCard widget**

```dart
// lib/presentation/pages/feed/components/lockout_placeholder_card.dart
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// A feed card displaying an active friend lockout as a placeholder.
///
/// Shows the goback logo, lockout info (time remaining/elapsed,
/// activity, location), and a "Join Lockout" button.
/// The timer updates every second for live countdown/countup.
class LockoutPlaceholderCard extends HookWidget {
  const LockoutPlaceholderCard({
    required this.session,
    required this.onJoinTap,
    super.key,
  });

  final LockoutSessionModel session;
  final VoidCallback onJoinTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final squircleSize = FeedLayout.squircleSize * s;
    final avatarSize = FeedLayout.avatarSize * s;
    final avatarInset = FeedLayout.avatarInsetFromSquircle * s;
    final avatarToName = FeedLayout.avatarToNameGap * s;
    final squircleToAuthor = FeedLayout.squircleToAuthorGap * s;
    final fontSize = FeedLayout.usernameFontSize * s;
    final letterSpacing = FeedLayout.usernameLetterSpacing * s;
    final nameMaxW = FeedLayout.nameMaxWidth(screenWidth);
    final leftInset = FeedLayout.leftPostInset * s;

    final displayName = session.username ?? 'Unknown';

    // Live timer — rebuilds every second
    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = DateTime.now();
      });
      return timer.cancel;
    }, []);

    final timeText = _buildTimeText(now.value);
    final infoLines = _buildInfoLines();

    return Padding(
      padding: EdgeInsets.only(left: leftInset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: squircleSize,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Squircle with goback logo + lockout info
              GestureDetector(
                onTap: onJoinTap,
                child: SizedBox(
                  width: squircleSize,
                  height: squircleSize,
                  child: ClipSquircle(
                    child: Container(
                      color: MainColors.dark,
                      child: Stack(
                        children: [
                          // Goback logo centered
                          Center(
                            child: Image.asset(
                              'assets/images/pngs/app_icon_foreground.png',
                              width: squircleSize * 0.4,
                              height: squircleSize * 0.4,
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Info overlay at bottom
                          Positioned(
                            left: 12 * s,
                            right: 12 * s,
                            bottom: 12 * s,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Time display
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontFamily: MainFontFamilies.quicksand,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18 * s,
                                    color: Colors.white,
                                    letterSpacing: -0.5 * s,
                                  ),
                                ),
                                if (infoLines.isNotEmpty) ...[
                                  SizedBox(height: 4 * s),
                                  ...infoLines.map(
                                    (line) => Padding(
                                      padding: EdgeInsets.only(top: 2 * s),
                                      child: Text(
                                        line,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily:
                                              MainFontFamilies.quicksand,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 13 * s,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          letterSpacing: -0.3 * s,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: squircleToAuthor),

              // Author row + join button
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 6 * s,
                  horizontal: avatarInset,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    SizedBox(
                      width: avatarSize,
                      height: avatarSize,
                      child: ClipOval(
                        child: (session.avatarUrl != null &&
                                session.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: session.avatarUrl!,
                                fit: BoxFit.cover,
                                width: avatarSize,
                                height: avatarSize,
                                memCacheWidth: (avatarSize * 2).toInt(),
                                memCacheHeight: (avatarSize * 2).toInt(),
                                placeholder: (_, __) => Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                                ),
                              )
                            : Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                              ),
                      ),
                    ),
                    SizedBox(width: avatarToName),
                    // Username
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: nameMaxW),
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w400,
                            fontSize: fontSize,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: letterSpacing,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    // Join button
                    GestureDetector(
                      onTap: onJoinTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * s,
                          vertical: 6 * s,
                        ),
                        decoration: BoxDecoration(
                          color: MainColors.dark,
                          borderRadius: BorderRadius.circular(16 * s),
                        ),
                        child: Text(
                          'Join',
                          style: TextStyle(
                            fontFamily: MainFontFamilies.quicksand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * s,
                            color: Colors.white,
                            letterSpacing: -0.3 * s,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTimeText(DateTime now) {
    if (session.isOpenEnded) {
      // Venue: count up from start
      final elapsed = now.difference(session.startedAt);
      return _formatDuration(elapsed);
    } else {
      // Timed: count down to end
      final remaining = session.endsAt.difference(now);
      if (remaining.isNegative) return '0:00';
      return _formatDuration(remaining);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  List<String> _buildInfoLines() {
    final lines = <String>[];
    if (session.actionText != null && session.actionText!.isNotEmpty) {
      lines.add(session.actionText!);
    }
    if (session.locationName != null && session.locationName!.isNotEmpty) {
      lines.add(session.locationName!);
    }
    return lines;
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter analyze lib/presentation/pages/feed/components/lockout_placeholder_card.dart`
Expected: No errors for this file.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/feed/components/lockout_placeholder_card.dart
git commit -m "feat: add LockoutPlaceholderCard widget for feed"
```

---

### Task 3: Update `useFeedPosts` hook to merge lockouts

**Files:**
- Modify: `lib/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart`

Changes the return type from `List<FeedPostModel>` to `List<FeedItem>`. Watches `friendsLockedOutCacheProvider`, filters, wraps, merges, and sorts.

- [ ] **Step 1: Update the FeedPostsResult typedef and imports**

At the top of `use_feed_posts.dart`, add the new imports and change the typedef:

Replace:
```dart
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
```

With:
```dart
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_item.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
```

Replace the typedef:
```dart
typedef FeedPostsResult = ({
  List<FeedPostModel> posts,
```

With:
```dart
typedef FeedPostsResult = ({
  List<FeedItem> posts,
```

- [ ] **Step 2: Add lockout merge logic to useFeedPosts**

Inside the `useFeedPosts` function, after the existing `posts` and `hasNextPage` lines (around line 57-58), add the lockout merge:

Replace:
```dart
  // Computed values from cache
  // Use notifier.posts for 24-hour filtered list, not raw cacheState.posts
  final posts = cacheNotifier.posts;
  final hasNextPage = cacheState.hasNextPage && !cacheState.fullyLoaded;
```

With:
```dart
  // Computed values from cache
  // Use notifier.posts for 24-hour filtered list, not raw cacheState.posts
  final rawPosts = cacheNotifier.posts;
  final hasNextPage = cacheState.hasNextPage && !cacheState.fullyLoaded;

  // Watch active friend lockouts for placeholder cards
  final lockoutCacheState = ref.watch(friendsLockedOutCacheProvider);

  // Merge posts and active friend lockouts into a unified feed
  final posts = useMemoized(() {
    final postItems = rawPosts.map(FeedItemPost.new).toList();

    // Filter lockouts: exclude own sessions and sessions user already joined
    final currentId = userId;
    final lockoutItems = lockoutCacheState.activeLockouts
        .where((s) => s.userId != currentId)
        .where((s) => !s.participants.contains(currentId))
        .map(FeedItemLockoutPlaceholder.new)
        .toList();

    final allItems = <FeedItem>[...postItems, ...lockoutItems];
    allItems.sort((a, b) => b.sortTimestamp.compareTo(a.sortTimestamp));
    return allItems;
  }, [rawPosts, lockoutCacheState.activeLockouts, userId]);
```

- [ ] **Step 3: Verify it compiles**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter analyze lib/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart`
Expected: Errors from downstream consumers (FeedPostsList, FeedView) expecting `List<FeedPostModel>` — these are fixed in Tasks 4 and 5. No errors within this file.

- [ ] **Step 4: Commit**

```bash
git add lib/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart
git commit -m "feat: merge active friend lockouts into feed items"
```

---

### Task 4: Update `FeedPostsList` to render `FeedItem` variants

**Files:**
- Modify: `lib/presentation/pages/feed/components/feed_posts_list.dart`

Changes the `posts` parameter from `List<FeedPostModel>` to `List<FeedItem>` and dispatches rendering to the correct card widget.

- [ ] **Step 1: Update imports**

Replace:
```dart
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
```

With:
```dart
import 'package:cloudless/core/features/post/domain/models/feed_item.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/feed/components/lockout_placeholder_card.dart';
```

- [ ] **Step 2: Update the class fields and constructor**

Replace:
```dart
  final List<FeedPostModel> posts;
  final String currentUserId;
  final bool isLoadingMore;
  final bool hasNextPage;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final void Function(FeedPostModel post)? onPostTap;
  final Future<bool> Function(FeedPostModel post)? onPostDelete;
  final void Function(DateTime? date)? onTopPostDateChanged;
  final void Function(bool isRefreshing)? onRefreshStateChanged;
```

With:
```dart
  final List<FeedItem> posts;
  final String currentUserId;
  final bool isLoadingMore;
  final bool hasNextPage;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final void Function(FeedPostModel post)? onPostTap;
  final Future<bool> Function(FeedPostModel post)? onPostDelete;
  final void Function(LockoutSessionModel session)? onJoinLockout;
  final void Function(DateTime? date)? onTopPostDateChanged;
  final void Function(bool isRefreshing)? onRefreshStateChanged;
```

Add the `onJoinLockout` parameter to the constructor:

Replace:
```dart
    this.onPostDelete,
    this.onTopPostDateChanged,
```

With:
```dart
    this.onPostDelete,
    this.onJoinLockout,
    this.onTopPostDateChanged,
```

Also add the import for LockoutSessionModel at the top:
```dart
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
```

- [ ] **Step 3: Update the sorting logic**

Replace:
```dart
    final sortedPosts = useMemoized(
      () =>
          List<FeedPostModel>.from(posts)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      [posts],
    );

    final sortedPostsRef = useRef<List<FeedPostModel>>([]);
```

With:
```dart
    final sortedPosts = useMemoized(
      () =>
          List<FeedItem>.from(posts)
            ..sort((a, b) => b.sortTimestamp.compareTo(a.sortTimestamp)),
      [posts],
    );

    final sortedPostsRef = useRef<List<FeedItem>>([]);
```

- [ ] **Step 4: Update the date tracking in scroll handler**

In the scroll handler (around line 93-110), update the date extraction to use `sortTimestamp`:

Replace:
```dart
            topDate = current[idx].createdAt.toLocal();
          } else {
            topDate = current.first.createdAt.toLocal();
```

With:
```dart
            topDate = current[idx].sortTimestamp.toLocal();
          } else {
            topDate = current.first.sortTimestamp.toLocal();
```

- [ ] **Step 5: Update the itemBuilder to dispatch by type**

Replace the itemBuilder body (lines 179-211):

Replace:
```dart
        itemBuilder: (context, index) {
          if (index == sortedPosts.length) {
            return const SizedBox.shrink();
          }
          final post = sortedPosts[index];
          final isCurrentUser = post.authorId == currentUserId;

          final card = FeedPostCard(
            key: ValueKey('feed_post_${post.id}'),
            post: post,
            isCurrentUser: isCurrentUser,
            onTap: onPostTap != null ? () => onPostTap!(post) : null,
          );

          if (!isCurrentUser || onPostDelete == null) return card;

          return Dismissible(
            key: ValueKey('dismiss_${post.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => onPostDelete!(post),
            background: const SizedBox.shrink(),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 24 * s),
              child: Icon(
                Icons.delete_rounded,
                color: MainColors.dark,
                size: 28 * s,
              ),
            ),
            child: card,
          );
        },
```

With:
```dart
        itemBuilder: (context, index) {
          if (index == sortedPosts.length) {
            return const SizedBox.shrink();
          }
          final item = sortedPosts[index];

          return switch (item) {
            FeedItemPost(:final post) => _buildPostCard(
                post,
                currentUserId,
                s,
              ),
            FeedItemLockoutPlaceholder(:final lockout) =>
              LockoutPlaceholderCard(
                key: ValueKey('lockout_${lockout.id}'),
                session: lockout,
                onJoinTap: () => onJoinLockout?.call(lockout),
              ),
          };
        },
```

- [ ] **Step 6: Add the _buildPostCard helper method**

Add this method inside the `build` method, just before the `return NotificationListener` statement (around line 126):

```dart
    Widget _buildPostCard(FeedPostModel post, String currentUserId, double s) {
      final isCurrentUser = post.authorId == currentUserId;
      final card = FeedPostCard(
        key: ValueKey('feed_post_${post.id}'),
        post: post,
        isCurrentUser: isCurrentUser,
        onTap: onPostTap != null ? () => onPostTap!(post) : null,
      );

      if (!isCurrentUser || onPostDelete == null) return card;

      return Dismissible(
        key: ValueKey('dismiss_${post.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onPostDelete!(post),
        background: const SizedBox.shrink(),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 24 * s),
          child: Icon(
            Icons.delete_rounded,
            color: MainColors.dark,
            size: 28 * s,
          ),
        ),
        child: card,
      );
    }
```

Note: Since this is a local function inside `build`, it can access the instance fields directly. Define it as a local function, not a method.

- [ ] **Step 7: Verify it compiles**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter analyze lib/presentation/pages/feed/components/feed_posts_list.dart`
Expected: No errors for this file (FeedView may still have errors, fixed in Task 5).

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/pages/feed/components/feed_posts_list.dart
git commit -m "feat: update FeedPostsList to render FeedItem variants"
```

---

### Task 5: Update `FeedView` for new types and join flow

**Files:**
- Modify: `lib/presentation/pages/feed/views/feed_view.dart`

Adds the `onJoinLockout` callback to `FeedPostsList` and updates date-overlay logic.

- [ ] **Step 1: Add imports**

Add these imports at the top of `feed_view.dart`:

```dart
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/post/domain/models/feed_item.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/join_lockout_dialog.dart';
```

- [ ] **Step 2: Add the join lockout handler**

In the `_buildStack` method, add a join handler before the `return Stack(` line (around line 424):

```dart
    Future<void> handleJoinLockout(
      BuildContext context,
      WidgetRef ref,
      LockoutSessionModel session,
    ) async {
      final confirmed = await JoinLockoutDialog.show(context, session);
      if (confirmed == true) {
        await ref
            .read(manualLockoutNotifierProvider.notifier)
            .joinLockout(session.id);
        if (context.mounted) {
          router.go(const ManualLockoutRoutable());
        }
      }
    }
```

- [ ] **Step 3: Pass `onJoinLockout` to FeedPostsList**

In the `_buildStack` method, update the `FeedPostsList` widget call:

Replace:
```dart
          FeedPostsList(
            posts: feedPosts.posts,
            currentUserId: currentUserId,
            isLoadingMore: feedPosts.isLoadingMore,
            hasNextPage: feedPosts.hasNextPage,
            onLoadMore: feedPosts.loadMore,
            onRefresh: feedPosts.refresh,
            scrollController: scrollController,
            onPostTap: (post) => PostDetailPage.show(context, post: post),
            onPostDelete: (post) => _confirmAndDeletePost(
              context,
              ref,
              post: post,
              currentUserId: currentUserId,
            ),
            onTopPostDateChanged: (date) => topPostDate.value = date,
            onRefreshStateChanged: (v) => isRefreshing.value = v,
          ),
```

With:
```dart
          FeedPostsList(
            posts: feedPosts.posts,
            currentUserId: currentUserId,
            isLoadingMore: feedPosts.isLoadingMore,
            hasNextPage: feedPosts.hasNextPage,
            onLoadMore: feedPosts.loadMore,
            onRefresh: feedPosts.refresh,
            scrollController: scrollController,
            onPostTap: (post) => PostDetailPage.show(context, post: post),
            onPostDelete: (post) => _confirmAndDeletePost(
              context,
              ref,
              post: post,
              currentUserId: currentUserId,
            ),
            onJoinLockout: (session) =>
                handleJoinLockout(context, ref, session),
            onTopPostDateChanged: (date) => topPostDate.value = date,
            onRefreshStateChanged: (v) => isRefreshing.value = v,
          ),
```

- [ ] **Step 4: Update the date overlay fallback**

The date overlay currently computes a fallback from `feedPosts.posts` using `FeedPostModel.createdAt`. Update it to use `FeedItem.sortTimestamp`:

Replace:
```dart
              child: FeedDateOverlay(
                displayDate:
                    topPostDate.value ??
                    (feedPosts.posts.isNotEmpty
                        ? feedPosts.posts
                              .reduce(
                                (a, b) =>
                                    a.createdAt.isAfter(b.createdAt) ? a : b,
                              )
                              .createdAt
                              .toLocal()
                        : null),
```

With:
```dart
              child: FeedDateOverlay(
                displayDate:
                    topPostDate.value ??
                    (feedPosts.posts.isNotEmpty
                        ? feedPosts.posts
                              .reduce(
                                (a, b) =>
                                    a.sortTimestamp.isAfter(b.sortTimestamp)
                                        ? a
                                        : b,
                              )
                              .sortTimestamp
                              .toLocal()
                        : null),
```

- [ ] **Step 5: Verify full app compiles**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter analyze --no-fatal-warnings`
Expected: No new errors (pre-existing warnings allowed per project config).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/feed/views/feed_view.dart
git commit -m "feat: wire up lockout placeholder join flow in FeedView"
```

---

### Task 6: Verify and test

- [ ] **Step 1: Run full analysis**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter analyze --no-fatal-warnings`
Expected: No new errors.

- [ ] **Step 2: Run tests**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter test`
Expected: All existing tests pass.

- [ ] **Step 3: Build the app**

Run: `cd /Users/goback/Documents/goback-app-lockv1 && fvm flutter build ios --flavor production --no-codesign`
Expected: Build succeeds.

- [ ] **Step 4: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix: resolve any compilation issues from placeholder post integration"
```
