import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/pages/post_detail/views/post_detail_view.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Helper class for handling navigation in post detail view.
class PostDetailNavigation with MainLayout, PostDetailLayout {
  /// Navigates to the user's profile based on whether they're the current user or connected.
  static Future<void> navigateToUserProfile(
    WidgetRef ref,
    String userId,
    String username,
  ) async {
    final currentUserAsync = ref.read(getCurrentUserProvider);
    final isCurrentUser =
        currentUserAsync.whenOrNull(
          data: (userResult) =>
              userResult.fold((user) => user.id == userId, (error) => false),
        ) ??
        false;

    if (isCurrentUser) {
      router.push(const ProfileRoutable());
    } else {
      final connectionResult = await ref.read(
        isUserConnectedProvider(userId).future,
      );
      final isConnected = connectionResult.fold((isConnected) => isConnected, (
        error,
      ) {
        logger.error('Failed to check user connection', exception: error);
        return false;
      });

      if (isConnected) {
        router.push(CircleProfileRoutable(userId: userId));
      } else {
        router.push(ExternalProfileRoutable(userId: userId));
      }
    }
  }

  /// Navigates to a parent post, handling both calendar and regular views.
  static Future<void> navigateToParentPost(
    BuildContext context,
    WidgetRef ref,
    String parentPostId,
    FeedPostModel currentPost, {
    required bool isFromCalendar,
    DateTime? headerDate,
    String? calendarUserId,
  }) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    DateTime? parentPostDate;
    if (isFromCalendar) {
      // Try to get the parent post's calendar date from cache
      final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);
      parentPostDate = cacheNotifier.getPostCalendarDate(parentPostId);

      // If not found in cache, use the current post's calendar date as fallback.
      // Since posts can only be replied to on the same day they were created
      // (feed visibility limitation), parent and reply posts will always share
      // the same calendar date when both are added to the calendar.
      parentPostDate ??= headerDate;
    }

    router.pop();

    await Future.delayed(const Duration(milliseconds: 300));

    if (!rootContext.mounted) {
      return;
    }

    if (isFromCalendar) {
      await PostDetailPage.showFromCalendarById(
        rootContext,
        postId: parentPostId,
        headerDate: parentPostDate,
        calendarUserId: calendarUserId,
      );
    } else {
      await showModalBottomSheet<void>(
        context: rootContext,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (sheetContext) => GestureDetector(
          onTap: () => Navigator.of(sheetContext).pop(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: 150.0,
                  bottom: 20.0,
                ),
                child: PostDetailView(
                  postId: parentPostId,
                  fallbackPost: null,
                  isFromCalendar: false,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
