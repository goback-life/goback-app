import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/get_feed_posts_provider.dart';
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

    final referenceTime = newestPostTimestamp.value;
    final bufferTime = referenceTime?.subtract(const Duration(seconds: 1));

    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        targetDate: DateTime.now(),
        pageSize: 15,
        cursorAfter: bufferTime,
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

    final referenceTime = newestPostTimestamp.value ?? DateTime.now();

    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        targetDate: referenceTime,
        pageSize: 15,
        cursorAfter: newestPostTimestamp.value,
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

    final referenceDate = posts.value.isNotEmpty
        ? posts.value.first.createdAt
        : DateTime.now();

    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        targetDate: referenceDate,
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

        if (deletedPostIds.isNotEmpty) {
          newPosts.removeWhere((p) => deletedPostIds.contains(p.id));
        }

        for (final updatedPost in updatedPosts) {
          final index = newPosts.indexWhere((p) => p.id == updatedPost.id);
          if (index != -1) {
            newPosts[index] = updatedPost;
          }
        }

        posts.value = newPosts;
      }
    }, (error) {});
  }
}
