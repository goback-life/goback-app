import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_month_notifier_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/get_calendar_posts_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_grid.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_header.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class ProfileCalendar extends HookConsumerWidget
    with MainLayout, ProfileLayout {
  const ProfileCalendar({this.userId, super.key});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentDate = DateTime.now();

    final selectedMonth = ref.watch(calendarMonthNotifierProvider);

    final currentUserAsync = ref.watch(getCurrentUserProvider);

    final calendarPostsByDay = useState(<String, CalendarPostModel>{});

    final calendarCache = ref.watch(calendarPostsCacheProvider);

    useEffect(() {
      calendarPostsByDay.value = {};

      final targetUserId =
          userId ??
          currentUserAsync.whenOrNull(
            data: (userResult) =>
                userResult.fold((user) => user.id, (_) => null),
          );

      if (targetUserId == null) {
        return null;
      }

      final isCurrentUser = userId == null;
      final cacheUserId = ref
          .read(calendarPostsCacheProvider.notifier)
          .currentUserId;

      final useCachedData =
          isCurrentUser &&
          cacheUserId == targetUserId &&
          calendarCache.isNotEmpty;

      if (useCachedData) {
        _filterCachedPosts(calendarCache, selectedMonth, calendarPostsByDay);
      } else {
        _loadCalendarForUser(
          ref,
          targetUserId,
          selectedMonth,
          calendarPostsByDay,
          () => context.mounted,
        );
      }

      return null;
    }, [currentUserAsync, selectedMonth, userId, calendarCache]);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(calendarBorderRadius),
          topRight: Radius.circular(calendarBorderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: CalendarHeader(
              selectedMonth: selectedMonth,
              onPreviousMonth: () {
                final prevMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                );
                ref
                    .read(calendarMonthNotifierProvider.notifier)
                    .setMonth(prevMonth);
              },
              onNextMonth:
                  selectedMonth.month >= currentDate.month &&
                      selectedMonth.year >= currentDate.year
                  ? null
                  : () {
                      final nextMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month + 1,
                      );
                      ref
                          .read(calendarMonthNotifierProvider.notifier)
                          .setMonth(nextMonth);
                    },
            ),
          ),
          SizedBox(height: verticalPadding),

          CalendarGrid(
            selectedMonth: selectedMonth,
            currentDate: currentDate,
            calendarThumbnails: calendarPostsByDay.value.map(
              (day, post) => MapEntry(day, post.thumbnailUrl ?? ''),
            ),
            onDayTap: (DateTime tappedDate) {
              final dateKey =
                  '${tappedDate.year}-${tappedDate.month.toString().padLeft(2, '0')}-${tappedDate.day.toString().padLeft(2, '0')}';
              final post = calendarPostsByDay.value[dateKey];

              final isDifferentMonth =
                  tappedDate.month != selectedMonth.month ||
                  tappedDate.year != selectedMonth.year;

              if (isDifferentMonth) {
                final currentMonthStart = DateTime(
                  currentDate.year,
                  currentDate.month,
                );
                final tappedMonthStart = DateTime(
                  tappedDate.year,
                  tappedDate.month,
                );
                if (tappedMonthStart.isBefore(currentMonthStart) ||
                    tappedMonthStart.isAtSameMomentAs(currentMonthStart)) {
                  ref
                      .read(calendarMonthNotifierProvider.notifier)
                      .setMonth(DateTime(tappedDate.year, tappedDate.month));
                }
              } else if (post != null) {
                _handleDayTapWithContent(
                  context,
                  ref,
                  post,
                  selectedMonth,
                  calendarPostsByDay,
                );
              }
            },
          ),
          SizedBox(height: bottomMargin),
        ],
      ),
    );
  }

  void _filterCachedPosts(
    List<CalendarPostModel> calendarCache,
    DateTime selectedMonth,
    ValueNotifier<Map<String, CalendarPostModel>> calendarPostsByDay,
  ) {
    final firstDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final startOffset = firstDayOfMonth.weekday % 7;
    final firstVisibleDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1 - startOffset,
    );

    final lastDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );
    final endOffset = 7 - lastDayOfMonth.weekday;
    final lastVisibleDay = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      endOffset,
    );

    final postsByDay = <String, CalendarPostModel>{};
    for (final post in calendarCache) {
      final postDate = post.publishedAt;
      if ((postDate.isAfter(firstVisibleDay) ||
              postDate.isAtSameMomentAs(firstVisibleDay)) &&
          (postDate.isBefore(lastVisibleDay) ||
              postDate.isAtSameMomentAs(lastVisibleDay))) {
        final dateKey =
            '${postDate.year}-${postDate.month.toString().padLeft(2, '0')}-${postDate.day.toString().padLeft(2, '0')}';
        postsByDay[dateKey] = post;
      }
    }

    calendarPostsByDay.value = postsByDay;
  }

  Future<void> _loadCalendarForUser(
    WidgetRef ref,
    String targetUserId,
    DateTime selectedMonth,
    ValueNotifier<Map<String, CalendarPostModel>> calendarPostsByDay,
    bool Function() isMounted,
  ) async {
    final lastDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );

    final endOffset = 7 - lastDayOfMonth.weekday;

    final lastVisibleDay = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      endOffset,
    );

    final calendarPostsProvider = getCalendarPostsProvider(
      userId: targetUserId,
      referenceDate: lastVisibleDay,
      direction: CalendarLoadDirection.before,
      limit: 42,
    );

    ref.invalidate(calendarPostsProvider);

    try {
      final calendarPostsAsync = await ref.read(calendarPostsProvider.future);

      if (!isMounted()) {
        return;
      }

      calendarPostsAsync.fold(
        (posts) {
          final currentUserAsync = ref.read(getCurrentUserProvider);
          final isCurrentUser =
              currentUserAsync.whenOrNull(
                data: (userResult) => userResult.fold(
                  (user) => user.id == targetUserId,
                  (_) => false,
                ),
              ) ??
              false;

          if (isCurrentUser) {
            ref
                .read(calendarPostsCacheProvider.notifier)
                .updateCache(posts, userId: targetUserId);
          }

          final postsByDay = <String, CalendarPostModel>{};
          for (final post in posts) {
            final dateKey =
                '${post.publishedAt.year}-${post.publishedAt.month.toString().padLeft(2, '0')}-${post.publishedAt.day.toString().padLeft(2, '0')}';
            postsByDay[dateKey] = post;
          }
          calendarPostsByDay.value = postsByDay;
        },
        (error) {
          final currentUserAsync = ref.read(getCurrentUserProvider);
          final isCurrentUser =
              currentUserAsync.whenOrNull(
                data: (userResult) => userResult.fold(
                  (user) => user.id == targetUserId,
                  (_) => false,
                ),
              ) ??
              false;

          if (isCurrentUser) {
            ref.read(calendarPostsCacheProvider.notifier).clearCache();
          }
          calendarPostsByDay.value = {};
        },
      );
    } catch (e) {
      if (isMounted()) {
        calendarPostsByDay.value = {};
      }
    }
  }

  Future<void> _handleDayTapWithContent(
    BuildContext context,
    WidgetRef ref,
    CalendarPostModel post,
    DateTime selectedMonth,
    ValueNotifier<Map<String, CalendarPostModel>> calendarPostsByDay,
  ) async {
    final feedPost = FeedPostModel(
      id: post.postId,
      authorId: post.authorId,
      authorUsername: post.authorUsername,
      authorAvatarUrl: post.authorAvatarUrl,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      imageUrl: post.thumbnailUrl,
      videoUrl: post.videoUrl,
      description: post.description,
      thumbnailWidth: post.thumbnailWidth,
      thumbnailHeight: post.thumbnailHeight,
      contentType: post.contentType,
      taggedUsernames: post.taggedUsernames,
      taggedUserIds: post.taggedUserIds,
      excludedUserIds: post.excludedUserIds,
      isAuthorConnected: post.isAuthorConnected,
      publishedAt: post.publishedAt,
      publishedTimezone: post.publishedTimezone,
      calendarSavedAt: post.publishedAt,
    );

    await PostDetailPage.showFromCalendar(
      context,
      post: feedPost,
      headerDate: post.publishedAt,
      calendarUserId: userId,
    );

    if (!context.mounted) {
      return;
    }

    String? targetUserId = userId;

    if (targetUserId == null) {
      final currentUserAsync = ref.read(getCurrentUserProvider);
      targetUserId = currentUserAsync.whenOrNull(
        data: (userResult) => userResult.fold((user) => user.id, (_) => null),
      );
    }

    if (targetUserId != null) {
      await _loadCalendarForUser(
        ref,
        targetUserId,
        selectedMonth,
        calendarPostsByDay,
        () => context.mounted,
      );
    }
  }
}
