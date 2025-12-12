import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/get_feed_posts_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Helper class for handling post actions (create, update, delete, hide, report).
class FeedPostsActions {
  /// Loads older posts for pagination.
  static Future<void> loadOlderPosts({
    required WidgetRef ref,
    required String userId,
    required DateTime effectiveTargetDate,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<bool> isLoadingMore,
    required ValueNotifier<bool> hasNextPage,
    required ValueNotifier<List<FeedPostModel>> posts,
    required ValueNotifier<DateTime?> oldestPostTimestamp,
    required ValueNotifier<String?> errorMessage,
  }) async {
    if (userId.isEmpty || userId.trim().isEmpty) {
      return;
    }

    if (isLoading.value || isLoadingMore.value || !hasNextPage.value) {
      return;
    }

    try {
      isLoadingMore.value = true;

      final result = await ref.read(
        getFeedPostsProvider(
          userId: userId,
          targetDate: effectiveTargetDate,
          pageSize: 15,
          cursorBefore: oldestPostTimestamp.value,
        ).future,
      );

      result.fold(
        (feedResponse) {
          if (feedResponse.posts.isNotEmpty) {
            // Filter duplicates using Set of IDs
            final existingIds = posts.value.map((p) => p.id).toSet();
            final newPosts = feedResponse.posts
                .where((p) => !existingIds.contains(p.id))
                .toList();

            if (newPosts.isNotEmpty) {
              posts.value = [...posts.value, ...newPosts];
              oldestPostTimestamp.value = newPosts.last.createdAt;
            }
          }

          hasNextPage.value = feedResponse.hasNextPage;
          errorMessage.value = null;
        },
        (error) {
          errorMessage.value = error.toString();
        },
      );
    } catch (e) {
      errorMessage.value = 'Unexpected error: ${e.toString()}';
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Loads initial posts when the feed is first displayed or refreshed.
  static Future<void> loadInitialPosts({
    required WidgetRef ref,
    required String userId,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<List<FeedPostModel>> posts,
    required ValueNotifier<bool> hasNextPage,
    required ValueNotifier<String?> errorMessage,
    required ValueNotifier<int> newPostsCount,
    required ValueNotifier<DateTime?> newestPostTimestamp,
    required ValueNotifier<DateTime?> oldestPostTimestamp,
  }) async {
    if (userId.isEmpty || userId.trim().isEmpty) {
      return;
    }

    try {
      isLoading.value = true;
      posts.value = [];
      hasNextPage.value = true;
      errorMessage.value = null;
      newPostsCount.value = 0;

      final currentTime = DateTime.now();

      final result = await ref.read(
        getFeedPostsProvider(
          userId: userId,
          targetDate: currentTime,
          pageSize: 15,
        ).future,
      );

      result.fold(
        (feedResponse) {
          posts.value = feedResponse.posts;
          hasNextPage.value = feedResponse.hasNextPage;

          if (feedResponse.posts.isNotEmpty) {
            newestPostTimestamp.value = feedResponse.posts.first.createdAt;
            oldestPostTimestamp.value = feedResponse.posts.last.createdAt;
          }

          errorMessage.value = null;
        },
        (error) {
          errorMessage.value = error.toString();
        },
      );
    } catch (e) {
      errorMessage.value = 'Errore imprevisto: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}
