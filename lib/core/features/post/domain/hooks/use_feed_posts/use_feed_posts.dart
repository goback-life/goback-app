import 'dart:async';

import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_item.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_published_notifier_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

typedef FeedPostsResult = ({
  List<FeedItem> posts,
  bool isLoading,
  bool isLoadingMore,
  bool hasNextPage,
  int newPostsCount,
  String? errorMessage,
  VoidCallback loadMore,
  Future<void> Function() refresh,
  VoidCallback loadNewPosts,
});

/// Custom hook for managing feed posts with cache-first loading.
///
/// Design:
/// 1. Returns cached posts immediately if available
/// 2. Loads first 15 posts on initial access
/// 3. Background loads remaining posts progressively (up to 200)
/// 4. UI updates reactively as more posts load
/// 5. Checks for deletions every 30 seconds
/// 6. Edits are NOT fetched for feed - only when user taps post detail
FeedPostsResult useFeedPosts(
  WidgetRef ref, {
  required String userId,
  DateTime? targetDate,
}) {
  // Watch the cache state - reactive updates as background loading progresses
  final cacheState = ref.watch(feedPostsCacheProvider);
  final cacheNotifier = ref.read(feedPostsCacheProvider.notifier);

  final isLoading = useState<bool>(false);
  final isLoadingMore = useState<bool>(false);
  final errorMessage = useState<String?>(null);
  final newPostsCount = useState<int>(0);

  // Track initialization
  final hasInitialized = useRef(false);
  final lastUserId = useRef<String?>(null);
  final isMounted = useRef(true);

  // Post action/publish listeners
  final postPublishedFlag = ref.watch(postPublishedNotifierProvider);
  final postActionEvent = ref.watch(postActionNotifierProvider);

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

  Future<void> loadNewPosts() async {
    if (newPostsCount.value > 0) {
      newPostsCount.value = 0;
    }
  }

  // Initialize feed and set up deletion polling
  useEffect(() {
    isMounted.value = true;
    Timer? deletionTimer;

    final shouldLoad =
        userId != lastUserId.value ||
        !hasInitialized.value ||
        (cacheNotifier.currentUserId != userId);

    if (shouldLoad && userId.isNotEmpty && userId.trim().isNotEmpty) {
      lastUserId.value = userId;
      hasInitialized.value = true;

      // Check if cache already has posts for this user
      if (cacheNotifier.currentUserId == userId &&
          cacheState.initialLoadComplete) {
        // Already have posts, check for new ones and deletions
        isLoading.value = false; // Ensure not loading
        cacheNotifier.refresh(userId);
        cacheNotifier.checkForDeletions(userId);
      } else {
        // Need to load initial posts
        isLoading.value = cacheNotifier.posts.isEmpty;

        cacheNotifier
            .loadInitialPosts(userId)
            .then((loadedPosts) {
              if (isMounted.value) {
                isLoading.value = false;
              }
            })
            .catchError((error) {
              if (isMounted.value) {
                isLoading.value = false;
                errorMessage.value = error.toString();
              }
            });
      }

      // Poll for deletions every 30 seconds (staggered to cover all posts)
      deletionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (isMounted.value) {
          cacheNotifier.checkForDeletionsStaggered(userId);
        }
      });
    } else if (userId.isEmpty || userId.trim().isEmpty) {
      // User logged out
      hasInitialized.value = false;
      lastUserId.value = null;
      isLoading.value = false;
      errorMessage.value = null;
      newPostsCount.value = 0;
    }

    return () {
      isMounted.value = false;
      deletionTimer?.cancel();
    };
  }, [userId]);

  // Handle post creation/delete/hide actions
  useEffect(() {
    if (postActionEvent != null && userId.isNotEmpty && isMounted.value) {
      switch (postActionEvent.action) {
        case PostActionType.create:
          if (postActionEvent.postId != null) {
            // Fetch the new post and add to cache
            cacheNotifier.fetchAndAddPost(postActionEvent.postId!).then((
              added,
            ) {
              if (!added) {
                // Fallback: refresh to find the new post
                cacheNotifier.refresh(userId);
              }
              ref.read(postActionNotifierProvider.notifier).clearAction();
            });
          } else {
            cacheNotifier.refresh(userId).then((_) {
              ref.read(postActionNotifierProvider.notifier).clearAction();
            });
          }
          break;
        case PostActionType.update:
          // Edits don't matter for feed preview (only description changes)
          // Post detail page refetches when opened
          Future(() {
            ref.read(postActionNotifierProvider.notifier).clearAction();
          });
          break;
        case PostActionType.delete:
        case PostActionType.hide:
        case PostActionType.report:
          // Defer to avoid modifying provider state during build phase.
          Future(() {
            if (postActionEvent.postId != null) {
              cacheNotifier.removePost(postActionEvent.postId!);
            }
            ref.read(postActionNotifierProvider.notifier).clearAction();
          });
          break;
      }
    }
    return null;
  }, [postActionEvent?.timestamp.millisecondsSinceEpoch]);

  // Handle post published flag
  useEffect(() {
    if (postPublishedFlag != null && userId.isNotEmpty && isMounted.value) {
      cacheNotifier.refresh(userId).then((_) {
        ref.read(postPublishedNotifierProvider.notifier).clearPublishedFlag();
      });
    }
    return null;
  }, [postPublishedFlag?.millisecondsSinceEpoch]);

  // Safety net: ensure isLoading is false when cache marks initial load complete
  useEffect(() {
    if (cacheState.initialLoadComplete && isLoading.value) {
      isLoading.value = false;
    }
    return null;
  }, [cacheState.initialLoadComplete]);

  /// Loads more posts - called when user scrolls to older posts.
  void loadMore() {
    if (isLoadingMore.value || isLoading.value) return;
    if (cacheState.fullyLoaded) return;
    if (userId.isEmpty) return;

    isLoadingMore.value = true;

    cacheNotifier
        .loadMorePostsNow(userId)
        .then((loaded) {
          if (isMounted.value) {
            isLoadingMore.value = false;
          }
        })
        .catchError((error) {
          if (isMounted.value) {
            isLoadingMore.value = false;
            errorMessage.value = error.toString();
          }
        });
  }

  /// Refreshes the feed - checks for new posts.
  Future<void> refresh() async {
    if (userId.isEmpty) return;
    await cacheNotifier.refresh(userId);
    await cacheNotifier.checkForDeletions(userId);
  }

  return (
    posts: posts,
    isLoading: isLoading.value,
    isLoadingMore: isLoadingMore.value || cacheState.isPreloading,
    hasNextPage: hasNextPage,
    newPostsCount: newPostsCount.value,
    errorMessage: errorMessage.value,
    loadMore: loadMore,
    refresh: refresh,
    loadNewPosts: loadNewPosts,
  );
}
