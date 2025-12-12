import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/providers/add_post_to_calendar_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/get_calendar_posts_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/remove_post_from_calendar_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Helper class for handling calendar operations in post detail view.
class PostDetailCalendar {
  /// Toggles a post's presence in the calendar (add or remove).
  static Future<void> handleCalendarToggle(
    BuildContext context,
    WidgetRef ref,
    FeedPostModel post,
    isCurrentlyInCalendar,
  ) async {
    final currentUserAsync = ref.read(getCurrentUserProvider);
    final userId = currentUserAsync.whenOrNull(
      data: (userResult) => userResult.fold((user) => user.id, (error) => null),
    );

    if (userId == null) {
      if (context.mounted) {
        await MainAlert.showError(
          context: context,
          title: translator.translate(
            'components.alert.calendar_error.error_title',
          ),
          content: translator.translate(
            'components.alert.calendar_error.error_content',
          ),
        );
      }
      return;
    }

    final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);

    if (isCurrentlyInCalendar) {
      await _removeFromCalendar(context, ref, post, userId, cacheNotifier);
    } else {
      await _addToCalendar(context, ref, post, userId, cacheNotifier);
    }
  }

  /// Removes a post from the calendar.
  static Future<void> _removeFromCalendar(
    BuildContext context,
    WidgetRef ref,
    FeedPostModel post,
    String userId,
    CalendarPostsCache cacheNotifier,
  ) async {
    final calendarDate = cacheNotifier.getPostCalendarDate(post.id);

    if (calendarDate == null) {
      return;
    }

    cacheNotifier.removePostOptimistically(post.id);

    final result = await ref.read(
      removePostFromCalendarProvider(calendarDate: calendarDate).future,
    );

    result.fold(
      (_) {
        // Success - cache already updated
      },
      (error) async {
        // Rollback: reload cache from database on error
        if (context.mounted) {
          await reloadCalendarCache(
            ref,
            userId,
            isMounted: () => context.mounted,
          );
        }

        if (context.mounted) {
          await MainAlert.showError(
            context: context,
            title: translator.translate(
              'components.alert.calendar_error.error_title',
            ),
            content: translator.translate(
              'components.alert.calendar_error.remove_error_content',
            ),
          );
        }
      },
    );
  }

  /// Adds a post to the calendar.
  static Future<void> _addToCalendar(
    BuildContext context,
    WidgetRef ref,
    FeedPostModel post,
    String userId,
    CalendarPostsCache cacheNotifier,
  ) async {
    final currentDate = DateTime.now();

    final result = await ref.read(
      addPostToCalendarProvider(
        postId: post.id,
        calendarDate: currentDate,
      ).future,
    );

    result.fold(
      (_) async {
        // Success - reload cache with fresh data from server
        if (context.mounted) {
          await reloadCalendarCache(
            ref,
            userId,
            isMounted: () => context.mounted,
          );
        }
      },
      (error) async {
        if (context.mounted) {
          await MainAlert.showError(
            context: context,
            title: translator.translate(
              'components.alert.calendar_error.error_title',
            ),
            content: translator.translate(
              'components.alert.calendar_error.add_error_content',
            ),
          );
        }
      },
    );
  }

  /// Reloads the calendar cache from the server.
  static Future<void> reloadCalendarCache(
    WidgetRef ref,
    String userId, {
    bool Function()? isMounted,
  }) async {
    final now = DateTime.now();

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final endOffset = 7 - lastDayOfMonth.weekday;
    final lastVisibleDay = DateTime(now.year, now.month + 1, endOffset);

    final result = await ref.read(
      getCalendarPostsProvider(
        userId: userId,
        referenceDate: lastVisibleDay,
        direction: CalendarLoadDirection.before,
        limit: 42,
      ).future,
    );

    // Check if widget is still mounted before using ref
    if (isMounted != null && !isMounted()) {
      return;
    }

    result.fold(
      (posts) {
        ref
            .read(calendarPostsCacheProvider.notifier)
            .updateCache(posts, userId: userId);
      },
      (error) {
        ref.read(calendarPostsCacheProvider.notifier).clearCache();
      },
    );
  }
}
