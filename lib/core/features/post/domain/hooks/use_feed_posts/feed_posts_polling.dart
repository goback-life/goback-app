import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/get_feed_posts_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/get_post_by_id_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Helper class for handling polling operations in feed posts.
class FeedPostsPolling {
  /// Checks for new posts published by other users since the last check.
  static Future<void> checkForNewPosts({
    required WidgetRef ref,
    required String userId,
    required ValueNotifier<List<FeedPostModel>> posts,
    required ValueNotifier<DateTime?> newestPostTimestamp,
    required ValueNotifier<int> newPostsCount,
  }) async {
    if (userId.isEmpty || userId.trim().isEmpty) {
      return;
    }

    // Load latest posts without cursor to check for new ones
    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: 15,
      ).future,
    );

    result.fold((feedResponse) {
      if (feedResponse.posts.isNotEmpty) {
        final existingIds = posts.value.map((p) => p.id).toSet();
        final actualNewPosts = feedResponse.posts
            .where((p) => !existingIds.contains(p.id))
            .toList();

        if (actualNewPosts.isNotEmpty) {
          posts.value = [...actualNewPosts, ...posts.value];
          newestPostTimestamp.value = actualNewPosts.first.createdAt;

          // Sync with cache
          ref.read(feedPostsCacheProvider.notifier).updateCache(posts.value);

          final postsFromOthers = actualNewPosts
              .where((p) => p.authorId != userId)
              .toList();

          if (postsFromOthers.isNotEmpty) {
            newPostsCount.value = postsFromOthers.length;
          }
        }
      }
    }, (error) {});

    // Refresh notification count when checking for new posts
    // (new posts may have generated new notifications)
    ref.invalidate(unreadNotificationCountProvider(userId: userId));
  }

  /// Checks for new posts with retry logic (used after post creation/publication).
  static Future<void> checkForNewPostsForRetry({
    required WidgetRef ref,
    required String userId,
    required ValueNotifier<List<FeedPostModel>> posts,
    required ValueNotifier<DateTime?> newestPostTimestamp,
    required ValueNotifier<DateTime?> oldestPostTimestamp,
    required ValueNotifier<int> newPostsCount,
  }) async {
    if (userId.isEmpty || userId.trim().isEmpty) {
      return;
    }

    // Load latest posts to check for new ones created after last fetch
    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: 15,
      ).future,
    );

    result.fold((feedResponse) {
      if (feedResponse.posts.isNotEmpty) {
        final existingIds = posts.value.map((p) => p.id).toSet();
        final actualNewPosts = feedResponse.posts
            .where((p) => !existingIds.contains(p.id))
            .toList();

        if (actualNewPosts.isNotEmpty) {
          posts.value = [...actualNewPosts, ...posts.value];
          newestPostTimestamp.value = actualNewPosts.first.createdAt;

          if (posts.value.length == actualNewPosts.length) {
            oldestPostTimestamp.value = actualNewPosts.last.createdAt;
          }

          // Sync with cache
          ref.read(feedPostsCacheProvider.notifier).updateCache(posts.value);

          final postsFromOthers = actualNewPosts
              .where((p) => p.authorId != userId)
              .toList();

          if (postsFromOthers.isNotEmpty) {
            newPostsCount.value = postsFromOthers.length;
          }
        }
      }
    }, (error) {});
  }

  /// Checks for new posts with retry mechanism.
  static Future<void> checkForNewPostsWithRetry({
    required WidgetRef ref,
    required String userId,
    required ValueNotifier<List<FeedPostModel>> posts,
    required ValueNotifier<DateTime?> newestPostTimestamp,
    required ValueNotifier<DateTime?> oldestPostTimestamp,
    required ValueNotifier<int> newPostsCount,
    required bool isMounted,
    int maxRetries = 3,
  }) async {
    if (userId.isEmpty || userId.trim().isEmpty) {
      return;
    }

    int attempt = 0;
    bool foundNewPosts = false;

    while (attempt < maxRetries && !foundNewPosts && isMounted) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }

      final previousPostCount = posts.value.length;
      await checkForNewPostsForRetry(
        ref: ref,
        userId: userId,
        posts: posts,
        newestPostTimestamp: newestPostTimestamp,
        oldestPostTimestamp: oldestPostTimestamp,
        newPostsCount: newPostsCount,
      );

      if (posts.value.length > previousPostCount) {
        foundNewPosts = true;
      } else {
        attempt++;
      }
    }
  }

  /// Immediately fetches a post by ID and adds it to the feed.
  /// Used when a post is just created to show it instantly.
  static Future<void> addPostImmediately({
    required WidgetRef ref,
    required String postId,
    required String userId,
    required ValueNotifier<List<FeedPostModel>> posts,
    required ValueNotifier<DateTime?> newestPostTimestamp,
    required ValueNotifier<DateTime?> oldestPostTimestamp,
  }) async {
    if (postId.isEmpty || userId.isEmpty || userId.trim().isEmpty) {
      return;
    }

    try {
      final result = await ref.read(getPostByIdProvider(postId: postId).future);

      result.fold(
        (feedPost) {
          // Check if post already exists in feed
          final existingIds = posts.value.map((p) => p.id).toSet();
          if (existingIds.contains(feedPost.id)) {
            return;
          }

          // Add post to the beginning of the feed
          posts.value = [feedPost, ...posts.value];

          // Update timestamps
          if (newestPostTimestamp.value == null ||
              feedPost.createdAt.isAfter(newestPostTimestamp.value!)) {
            newestPostTimestamp.value = feedPost.createdAt;
          }

          // If this is the first post, set it as oldest too
          if (posts.value.length == 1) {
            oldestPostTimestamp.value = feedPost.createdAt;
          }

          // Sync with cache
          ref.read(feedPostsCacheProvider.notifier).addPost(feedPost);

          // Refresh notification count (new posts may have generated notifications)
          ref.invalidate(unreadNotificationCountProvider(userId: userId));
        },
        (error) {
          // Silently fail - the retry mechanism will handle it
        },
      );
    } catch (e) {
      // Silently fail - the retry mechanism will handle it
    }
  }

  /// Checks for post updates (edits, deletions) in existing posts.
  static Future<void> checkForPostUpdates({
    required WidgetRef ref,
    required String userId,
    required ValueNotifier<List<FeedPostModel>> posts,
  }) async {
    if (posts.value.isEmpty) {
      return;
    }

    if (userId.isEmpty || userId.trim().isEmpty) {
      return;
    }

    // Load posts to check for updates
    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: posts.value.length + 10,
      ).future,
    );

    result.fold((feedResponse) {
      final currentPosts = posts.value;
      final receivedPostsMap = {for (final p in feedResponse.posts) p.id: p};

      final deletedPostIds = currentPosts
          .where((p) => !receivedPostsMap.containsKey(p.id))
          .map((p) => p.id)
          .toSet();

      final updatedPosts = <FeedPostModel>[];

      for (final currentPost in currentPosts) {
        final receivedPost = receivedPostsMap[currentPost.id];
        if (receivedPost != null &&
            receivedPost.updatedAt.isAfter(currentPost.updatedAt)) {
          updatedPosts.add(receivedPost);
        }
      }

      if (deletedPostIds.isNotEmpty || updatedPosts.isNotEmpty) {
        final newPosts = List<FeedPostModel>.from(currentPosts);
        final cacheNotifier = ref.read(feedPostsCacheProvider.notifier);

        if (deletedPostIds.isNotEmpty) {
          newPosts.removeWhere((p) => deletedPostIds.contains(p.id));
          // Sync deletions with cache
          for (final id in deletedPostIds) {
            cacheNotifier.removePost(id);
          }
        }

        for (final updatedPost in updatedPosts) {
          final index = newPosts.indexWhere((p) => p.id == updatedPost.id);
          if (index != -1) {
            newPosts[index] = updatedPost;
            // Sync update with cache
            cacheNotifier.updatePost(updatedPost);
          }
        }

        posts.value = newPosts;
      }
    }, (error) {});
  }
}
