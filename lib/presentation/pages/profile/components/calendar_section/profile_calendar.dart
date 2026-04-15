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

/// Number of months to preload into cache (current + N-1 previous).
const _kPreloadMonths = 3;

/// First visible day of the calendar grid (Monday-first weeks).
DateTime _gridStart(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  return DateTime(month.year, month.month, 1 - (first.weekday - 1));
}

/// Last visible day of the calendar grid (6-week max = 42 cells).
DateTime _gridEnd(DateTime month) {
  return _gridStart(month).add(const Duration(days: 41));
}

/// Fetches calendar posts for multiple months in parallel.
Future<List<CalendarPostModel>?> _fetchMonths(
  WidgetRef ref,
  String userId,
  List<DateTime> months,
) async {
  final futures = months.map((m) {
    final p = getCalendarPostsProvider(
      userId: userId,
      referenceDate: m,
      direction: CalendarLoadDirection.before,
      limit: 42,
    );
    return ref.read(p.future);
  }).toList();

  try {
    final results = await Future.wait(futures);
    final allPosts = <CalendarPostModel>[];
    for (final result in results) {
      result.fold((posts) => allPosts.addAll(posts), (error) {});
    }
    return allPosts;
  } catch (e) {
    return null;
  }
}

/// Preloads calendar data for the current user into the cache.
/// Call once from an authenticated widget (e.g. HomePage) for instant display.
Future<void> preloadCalendarCache(WidgetRef ref) async {
  final currentUserAsync = ref.read(getCurrentUserProvider);
  final userId = currentUserAsync.whenOrNull(
    data: (result) => result.fold((user) => user.id, (_) => null),
  );
  if (userId == null) return;

  final cache = ref.read(calendarPostsCacheProvider);
  final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);
  if (cacheNotifier.currentUserId == userId && cache.isNotEmpty) return;

  final now = DateTime.now();
  final months = [
    for (var i = 0; i < _kPreloadMonths; i++) DateTime(now.year, now.month - i),
  ];

  final allPosts = await _fetchMonths(ref, userId, months);
  if (allPosts == null) return;

  cacheNotifier.mergePosts(
    allPosts,
    userId: userId,
    rangeStart: _gridStart(months.last),
    rangeEnd: _gridEnd(months.first),
  );
}

class ProfileCalendar extends HookConsumerWidget
    with MainLayout, ProfileLayout {
  const ProfileCalendar({this.userId, this.scale = 1.0, super.key});

  final String? userId;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDate = DateTime.now();
    final selectedMonth = ref.watch(calendarMonthNotifierProvider);
    final currentUserAsync = ref.watch(getCurrentUserProvider);
    final calendarPostsByDay = useState(<String, CalendarPostModel>{});
    final calendarCache = ref.watch(calendarPostsCacheProvider);

    // Display effect: show cache instantly whenever cache or month changes.
    useEffect(() {
      final targetUserId =
          userId ??
          currentUserAsync.whenOrNull(
            data: (userResult) =>
                userResult.fold((user) => user.id, (_) => null),
          );

      if (targetUserId == null) {
        calendarPostsByDay.value = {};
        return null;
      }

      final isCurrentUser = userId == null;
      final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);
      final hasCachedData =
          isCurrentUser &&
          cacheNotifier.currentUserId == targetUserId &&
          calendarCache.isNotEmpty;

      if (hasCachedData) {
        _filterCachedPosts(calendarCache, selectedMonth, calendarPostsByDay);
      }

      return null;
    }, [currentUserAsync, selectedMonth, userId, calendarCache]);

    // Fetch effect: refresh from network on month/user change.
    // For own user, preloads last 3 months on first fetch.
    useEffect(() {
      final targetUserId =
          userId ??
          currentUserAsync.whenOrNull(
            data: (userResult) =>
                userResult.fold((user) => user.id, (_) => null),
          );

      if (targetUserId == null) return null;

      final isCurrentUser = userId == null;

      if (!isCurrentUser) {
        calendarPostsByDay.value = {};
      }

      _loadCalendarForUser(
        ref,
        targetUserId,
        selectedMonth,
        calendarPostsByDay,
        () => context.mounted,
        isCurrentUser: isCurrentUser,
      );

      return null;
    }, [currentUserAsync, selectedMonth, userId]);

    final canGoNext =
        !(selectedMonth.month >= currentDate.month &&
            selectedMonth.year >= currentDate.year);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) {
          return;
        }
        if (details.primaryVelocity! > 0) {
          ref
              .read(calendarMonthNotifierProvider.notifier)
              .setMonth(DateTime(selectedMonth.year, selectedMonth.month - 1));
        } else if (details.primaryVelocity! < 0 && canGoNext) {
          ref
              .read(calendarMonthNotifierProvider.notifier)
              .setMonth(DateTime(selectedMonth.year, selectedMonth.month + 1));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: CalendarGrid(
                selectedMonth: selectedMonth,
                currentDate: currentDate,
                scale: scale,
                calendarThumbnails: calendarPostsByDay.value.map(
                  (day, post) => MapEntry(day, post.thumbnailUrl ?? ''),
                ),
                onDayTap: (DateTime tappedDate) {
                  _handleDayTap(
                    context,
                    ref,
                    tappedDate,
                    selectedMonth,
                    currentDate,
                    calendarPostsByDay,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          CalendarHeader(
            selectedMonth: selectedMonth,
            scale: scale,
            onPreviousMonth: () {
              ref
                  .read(calendarMonthNotifierProvider.notifier)
                  .setMonth(
                    DateTime(selectedMonth.year, selectedMonth.month - 1),
                  );
            },
            onNextMonth: canGoNext
                ? () {
                    ref
                        .read(calendarMonthNotifierProvider.notifier)
                        .setMonth(
                          DateTime(selectedMonth.year, selectedMonth.month + 1),
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _handleDayTap(
    BuildContext context,
    WidgetRef ref,
    DateTime tappedDate,
    DateTime selectedMonth,
    DateTime currentDate,
    ValueNotifier<Map<String, CalendarPostModel>> calendarPostsByDay,
  ) {
    final dateKey =
        '${tappedDate.year}-${tappedDate.month.toString().padLeft(2, '0')}-${tappedDate.day.toString().padLeft(2, '0')}';
    final post = calendarPostsByDay.value[dateKey];

    final isDifferentMonth =
        tappedDate.month != selectedMonth.month ||
        tappedDate.year != selectedMonth.year;

    if (isDifferentMonth) {
      final currentMonthStart = DateTime(currentDate.year, currentDate.month);
      final tappedMonthStart = DateTime(tappedDate.year, tappedDate.month);
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
  }

  void _filterCachedPosts(
    List<CalendarPostModel> cache,
    DateTime selectedMonth,
    ValueNotifier<Map<String, CalendarPostModel>> calendarPostsByDay,
  ) {
    final start = _gridStart(selectedMonth);
    final end = _gridEnd(selectedMonth);

    final postsByDay = <String, CalendarPostModel>{};
    for (final post in cache) {
      // Normalize to date-only for comparison (ignore time component).
      final d = DateTime(
        post.publishedAt.year,
        post.publishedAt.month,
        post.publishedAt.day,
      );
      if (!d.isBefore(start) && !d.isAfter(end)) {
        final dateKey =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
    bool Function() isMounted, {
    bool isCurrentUser = false,
  }) async {
    if (isCurrentUser) {
      // Check if cache already covers this month's grid range.
      final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);
      final cache = ref.read(calendarPostsCacheProvider);
      final gridS = _gridStart(selectedMonth);
      final gridE = _gridEnd(selectedMonth);
      final cacheCovers =
          cacheNotifier.currentUserId == targetUserId &&
          cache.any(
            (p) =>
                !DateTime(
                  p.publishedAt.year,
                  p.publishedAt.month,
                  p.publishedAt.day,
                ).isBefore(gridS) &&
                !DateTime(
                  p.publishedAt.year,
                  p.publishedAt.month,
                  p.publishedAt.day,
                ).isAfter(gridE),
          );
      if (cacheCovers) return; // Cache already has data for this range.

      // Only fetch the single selected month (preloadCalendarCache already
      // covers the initial 3-month window on startup).
      final allPosts = await _fetchMonths(ref, targetUserId, [selectedMonth]);
      if (allPosts == null || !isMounted()) return;

      ref
          .read(calendarPostsCacheProvider.notifier)
          .mergePosts(
            allPosts,
            userId: targetUserId,
            rangeStart: gridS,
            rangeEnd: gridE,
          );
      // Display is updated by the display effect reacting to cache change.
    } else {
      final allPosts = await _fetchMonths(ref, targetUserId, [selectedMonth]);
      if (allPosts == null || !isMounted()) return;

      final postsByDay = <String, CalendarPostModel>{};
      for (final post in allPosts) {
        final d = DateTime(
          post.publishedAt.year,
          post.publishedAt.month,
          post.publishedAt.day,
        );
        final dateKey =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        postsByDay[dateKey] = post;
      }
      calendarPostsByDay.value = postsByDay;
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

    await PostDetailPage.show(
      context,
      post: feedPost,
      readOnly: userId != null,
      isFromCalendar: true,
    );

    if (!context.mounted) return;

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
        isCurrentUser: userId == null,
      );
    }
  }
}
