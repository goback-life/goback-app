import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_navigation_header.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/utilities/post_detail_calendar_navigation.dart';
import 'package:cloudless/presentation/pages/post_detail/views/post_detail_overlay.dart';
import 'package:cloudless/presentation/pages/post_detail/views/post_detail_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// A draggable bottom sheet that displays the post detail view.
///
/// This component wraps the [PostDetailView] in a [DraggableScrollableSheet]
/// to allow users to view post details as an overlay on the home screen.
class PostDetailPage extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailPage({
    required this.post,
    this.isFromCalendar = false,
    this.headerDate,
    this.calendarUserId,
    super.key,
  }) : postId = null;

  const PostDetailPage.byId({
    required String this.postId,
    this.isFromCalendar = false,
    this.headerDate,
    this.calendarUserId,
    super.key,
  }) : post = null;

  final FeedPostModel? post;
  final String? postId;
  final bool isFromCalendar;
  final DateTime? headerDate;
  final String? calendarUserId;

  /// Shows the post detail as a glass overlay with Hero transition.
  ///
  /// Uses [Navigator.push] with a transparent [PageRouteBuilder] so that the
  /// squircle image can animate from the feed card to the overlay position.
  /// Returns a [Future] that completes when the overlay is dismissed.
  static Future<void> show(
    BuildContext context, {
    required FeedPostModel post,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: PostDetailOverlay(post: post),
          );
        },
      ),
    );
  }

  /// Shows the post detail from calendar with green background.
  ///
  /// Returns a [Future] that completes when the overlay is dismissed.
  static Future<void> showFromCalendar(
    BuildContext context, {
    required FeedPostModel post,
    DateTime? headerDate,
    String? calendarUserId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: PostDetailPage(
          post: post,
          isFromCalendar: true,
          headerDate: headerDate,
          calendarUserId: calendarUserId,
        ),
      ),
    );
  }

  /// Shows the post detail from calendar by ID with green background.
  ///
  /// This is useful when navigating to a parent post where we only have the ID.
  /// Returns a [Future] that completes when the overlay is dismissed.
  static Future<void> showFromCalendarById(
    BuildContext context, {
    required String postId,
    DateTime? headerDate,
    String? calendarUserId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: PostDetailPage.byId(
          postId: postId,
          isFromCalendar: true,
          headerDate: headerDate,
          calendarUserId: calendarUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final targetUserId = useMemoized(() {
      if (calendarUserId != null) {
        return calendarUserId;
      }

      final currentUserAsync = ref.read(getCurrentUserProvider);
      return currentUserAsync.whenOrNull(
        data: (userResult) =>
            userResult.fold((user) => user.id, (error) => null),
      );
    }, [calendarUserId]);

    final currentPostId = useState(postId ?? post?.id ?? '');

    final currentPostAuthorId = useState<String?>(post?.authorId);

    final noMoreNextPosts = useState<bool?>(null);
    final noMorePreviousPosts = useState<bool?>(null);

    final currentPostDate = useState<DateTime?>(() {
      if (!isFromCalendar) {
        return null;
      }

      final initialId = postId ?? post?.id;

      if (initialId != null) {
        final dateFromCache = ref
            .read(calendarPostsCacheProvider.notifier)
            .getPostCalendarDate(initialId);
        if (dateFromCache != null) {
          return dateFromCache;
        }
      }

      return headerDate;
    }());

    useEffect(() {
      if (isFromCalendar && targetUserId != null) {
        final dateToUse = currentPostDate.value ?? headerDate;

        if (dateToUse == null) {
          return null;
        }

        final cacheUserId = ref
            .read(calendarPostsCacheProvider.notifier)
            .currentUserId;

        final needsReload = cacheUserId != targetUserId;

        final postInCache =
            currentPostId.value.isNotEmpty &&
            ref
                    .read(calendarPostsCacheProvider.notifier)
                    .getPostCalendarDate(currentPostId.value) !=
                null;

        if (needsReload || !postInCache) {
          PostDetailCalendarNavigation.loadMonthPosts(
            ref: ref,
            month: dateToUse,
            targetUserId: targetUserId,
            calendarUserId: calendarUserId,
          );
        }
      }
      return null;
    }, [targetUserId, currentPostId.value]);

    useEffect(() {
      if (isFromCalendar && currentPostId.value.isNotEmpty) {
        final dateFromCache = ref
            .read(calendarPostsCacheProvider.notifier)
            .getPostCalendarDate(currentPostId.value);

        if (dateFromCache != null) {
          currentPostDate.value = dateFromCache;
        }

        final cachedPosts = ref.read(calendarPostsCacheProvider);

        try {
          final postFromCache = cachedPosts.firstWhere(
            (p) => p.postId == currentPostId.value,
          );
          currentPostAuthorId.value = postFromCache.authorId;
        } catch (e) {
          return null;
        }
      }
      return null;
    }, [currentPostId.value, ref.watch(calendarPostsCacheProvider)]);

    useEffect(() {
      noMoreNextPosts.value = null;
      noMorePreviousPosts.value = null;
      return null;
    }, [currentPostId.value, targetUserId]);

    useEffect(
      () {
        if (!isFromCalendar ||
            currentPostDate.value == null ||
            targetUserId == null) {
          return null;
        }

        final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);

        if (cacheNotifier.currentUserId != targetUserId) {
          return null;
        }

        final currentPostInCache =
            currentPostId.value.isNotEmpty &&
            cacheNotifier.getPostCalendarDate(currentPostId.value) != null;

        if (!currentPostInCache) {
          return null;
        }

        final nextPost = cacheNotifier.getNextPost(
          currentPostDate.value!,
          authorId: targetUserId,
        );

        noMoreNextPosts.value = (nextPost == null);

        final previousPost = cacheNotifier.getPreviousPost(
          currentPostDate.value!,
          authorId: targetUserId,
        );

        noMorePreviousPosts.value = (previousPost == null);

        return null;
      },
      [
        currentPostDate.value,
        targetUserId,
        currentPostId.value,
        ref.watch(calendarPostsCacheProvider),
      ],
    );

    final hasNextPost = useMemoized(
      () {
        if (!isFromCalendar ||
            currentPostDate.value == null ||
            targetUserId == null) {
          return false;
        }

        if (noMoreNextPosts.value == true) {
          return false;
        }

        final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);
        final nextPost = cacheNotifier.getNextPost(
          currentPostDate.value!,
          authorId: targetUserId,
        );

        if (nextPost != null) {
          return true;
        }

        final currentDate = currentPostDate.value!;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final currentPostDateOnly = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );

        if (currentPostDateOnly.isAtSameMomentAs(today) ||
            currentPostDateOnly.isAfter(today)) {
          return false;
        }

        return true;
      },
      [
        currentPostDate.value,
        targetUserId,
        noMoreNextPosts.value,
        ref.watch(calendarPostsCacheProvider),
      ],
    );

    final hasPreviousPost = useMemoized(
      () {
        if (!isFromCalendar ||
            currentPostDate.value == null ||
            targetUserId == null) {
          return false;
        }

        if (noMorePreviousPosts.value != null) {
          final result = !noMorePreviousPosts.value!;

          return result;
        }

        final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);

        final dateFromCache = currentPostId.value.isNotEmpty
            ? cacheNotifier.getPostCalendarDate(currentPostId.value)
            : null;

        if (dateFromCache == null) {
          return false;
        }

        if (dateFromCache != currentPostDate.value) {
          return false;
        }

        final previousPost = cacheNotifier.getPreviousPost(
          currentPostDate.value!,
          authorId: targetUserId,
        );

        final result = previousPost != null;

        return result;
      },
      [
        currentPostDate.value,
        targetUserId,
        noMorePreviousPosts.value,
        currentPostId.value,
        ref.watch(calendarPostsCacheProvider),
      ],
    );

    final isParentPost = useMemoized(() {
      return postId != null;
    }, [postId]);

    return GestureDetector(
      onTap: isFromCalendar ? null : () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isFromCalendar
            ? BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(postDetailPageBorderRadius),
                ),
              )
            : const BoxDecoration(color: Colors.transparent),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: EdgeInsets.only(
              left: sheetHorizontalPosition,
              right: sheetHorizontalPosition,
              top: isFromCalendar
                  ? sheetTopPosition - postDetailPageTopOffset
                  : sheetTopPosition,
              bottom: isFromCalendar
                  ? sheetBottomPosition + postDetailPageBottomOffset
                  : sheetBottomPosition,
            ),
            child: Column(
              children: [
                if (isFromCalendar && currentPostDate.value != null)
                  PostNavigationHeader(
                    currentDate: currentPostDate.value!,
                    showNavigationArrows: !isParentPost,
                    onPreviousPost: hasPreviousPost
                        ? () => PostDetailCalendarNavigation.handlePreviousPost(
                            ref: ref,
                            currentPostId: currentPostId,
                            currentPostDate: currentPostDate,
                            currentPostAuthorId: currentPostAuthorId,
                            noMorePreviousPosts: noMorePreviousPosts,
                            targetUserId: targetUserId,
                            calendarUserId: calendarUserId,
                          )
                        : null,
                    onNextPost: hasNextPost
                        ? () => PostDetailCalendarNavigation.handleNextPost(
                            ref: ref,
                            currentPostId: currentPostId,
                            currentPostDate: currentPostDate,
                            currentPostAuthorId: currentPostAuthorId,
                            noMoreNextPosts: noMoreNextPosts,
                            targetUserId: targetUserId,
                            calendarUserId: calendarUserId,
                          )
                        : null,
                  ),
                SizedBox(
                  height: isFromCalendar && currentPostDate.value != null
                      ? postDetailPageHeaderSpacing
                      : 0.0,
                ),
                Expanded(
                  child: PostDetailView(
                    postId: currentPostId.value,
                    fallbackPost: post,
                    isFromCalendar: isFromCalendar,
                    calendarUserId: calendarUserId,
                    headerDate: currentPostDate.value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
