import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/get_calendar_posts_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper class for handling calendar navigation in post detail page.
class PostDetailCalendarNavigation {
  /// Handles navigation to the previous post in the calendar.
  static Future<void> handlePreviousPost({
    required WidgetRef ref,
    required ValueNotifier<String> currentPostId,
    required ValueNotifier<DateTime?> currentPostDate,
    required ValueNotifier<String?> currentPostAuthorId,
    required ValueNotifier<bool?> noMorePreviousPosts,
    required String? targetUserId,
    String? calendarUserId,
  }) async {
    if (currentPostDate.value == null || targetUserId == null) {
      return;
    }

    final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);

    final isNearBeginning = cacheNotifier.isNearBeginning(
      currentPostDate.value!,
      authorId: targetUserId,
      threshold: 3,
    );

    var previousPost = cacheNotifier.getPreviousPost(
      currentPostDate.value!,
      authorId: targetUserId,
    );

    if (isNearBeginning || previousPost == null) {
      await loadMorePosts(
        ref: ref,
        referenceDate: currentPostDate.value!,
        direction: CalendarLoadDirection.before,
        targetUserId: targetUserId,
        calendarUserId: calendarUserId,
        limit: 10,
      );

      previousPost = cacheNotifier.getPreviousPost(
        currentPostDate.value!,
        authorId: targetUserId,
      );

      if (previousPost == null) {
        noMorePreviousPosts.value = true;
        return;
      }
    }

    currentPostId.value = previousPost.postId;
    currentPostDate.value = previousPost.publishedAt;
    currentPostAuthorId.value = previousPost.authorId;
    noMorePreviousPosts.value = false;
  }

  /// Handles navigation to the next post in the calendar.
  static Future<void> handleNextPost({
    required WidgetRef ref,
    required ValueNotifier<String> currentPostId,
    required ValueNotifier<DateTime?> currentPostDate,
    required ValueNotifier<String?> currentPostAuthorId,
    required ValueNotifier<bool?> noMoreNextPosts,
    required String? targetUserId,
    String? calendarUserId,
  }) async {
    if (currentPostDate.value == null || targetUserId == null) {
      return;
    }

    final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);

    final isNearEnd = cacheNotifier.isNearEnd(
      currentPostDate.value!,
      authorId: targetUserId,
      threshold: 3,
    );

    var nextPost = cacheNotifier.getNextPost(
      currentPostDate.value!,
      authorId: targetUserId,
    );

    if (isNearEnd || nextPost == null) {
      await loadMorePosts(
        ref: ref,
        referenceDate: currentPostDate.value!,
        direction: CalendarLoadDirection.after,
        targetUserId: targetUserId,
        calendarUserId: calendarUserId,
        limit: 10,
      );

      nextPost = cacheNotifier.getNextPost(
        currentPostDate.value!,
        authorId: targetUserId,
      );

      if (nextPost == null) {
        noMoreNextPosts.value = true;
        return;
      }
    }

    currentPostId.value = nextPost.postId;
    currentPostDate.value = nextPost.publishedAt;
    currentPostAuthorId.value = nextPost.authorId;
    noMoreNextPosts.value = false;
  }

  /// Loads more calendar posts incrementally (for navigation).
  /// This loads a smaller batch of posts (default: 10) to extend the cache.
  static Future<void> loadMorePosts({
    required WidgetRef ref,
    required DateTime referenceDate,
    required CalendarLoadDirection direction,
    required String? targetUserId,
    String? calendarUserId,
    int limit = 10,
  }) async {
    String? userId = calendarUserId ?? targetUserId;

    if (userId == null) {
      final currentUserAsync = ref.read(getCurrentUserProvider);
      userId = currentUserAsync.whenOrNull(
        data: (userResult) =>
            userResult.fold((user) => user.id, (error) => null),
      );
    }

    if (userId == null) {
      logger.error(
        '[CalendarNavigationHelper] loadMorePosts - Cannot load posts: userId is null',
      );
      return;
    }

    final result = await ref.read(
      getCalendarPostsProvider(
        userId: userId,
        referenceDate: referenceDate,
        direction: direction,
        limit: limit,
      ).future,
    );

    result.fold(
      (posts) {
        if (userId != null) {
          ref.read(calendarPostsCacheProvider.notifier).appendPosts(posts);
        }
      },
      (error) {
        logger.error(
          '[CalendarNavigationHelper] loadMorePosts - Error loading posts: $error',
        );
      },
    );
  }

  /// Loads calendar posts for a specific month (for initial load).
  static Future<void> loadMonthPosts({
    required WidgetRef ref,
    required DateTime month,
    required String? targetUserId,
    String? calendarUserId,
  }) async {
    String? userId = calendarUserId ?? targetUserId;

    if (userId == null) {
      final currentUserAsync = ref.read(getCurrentUserProvider);
      userId = currentUserAsync.whenOrNull(
        data: (userResult) =>
            userResult.fold((user) => user.id, (error) => null),
      );
    }

    if (userId == null) {
      logger.error(
        '[CalendarNavigationHelper] loadMonthPosts - Cannot load posts: userId is null',
      );
      return;
    }

    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final endOffset = 7 - lastDayOfMonth.weekday;
    final lastVisibleDay = DateTime(month.year, month.month + 1, endOffset);

    final result = await ref.read(
      getCalendarPostsProvider(
        userId: userId,
        referenceDate: lastVisibleDay,
        direction: CalendarLoadDirection.before,
        limit: 42,
      ).future,
    );

    result.fold(
      (posts) {
        if (userId != null) {
          ref
              .read(calendarPostsCacheProvider.notifier)
              .updateCache(posts, userId: userId);
        }
      },
      (error) {
        logger.error(
          '[CalendarNavigationHelper] loadMonthPosts - Error loading posts: $error',
        );
      },
    );
  }
}
