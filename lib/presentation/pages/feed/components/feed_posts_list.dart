import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_post_card.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Reversed ListView for the V1 feed.
///
/// Newest posts at bottom (offset 0), scroll up for older.
/// Triggers pagination when approaching the older-posts edge.
/// Pull-to-refresh (overscroll at bottom) calls [onRefresh].
class FeedPostsList extends HookConsumerWidget {
  const FeedPostsList({
    required this.posts,
    required this.currentUserId,
    required this.isLoadingMore,
    required this.hasNextPage,
    required this.onLoadMore,
    required this.onRefresh,
    required this.scrollController,
    this.onPostTap,
    this.onPostDelete,
    this.onTopPostDateChanged,
    this.onRefreshStateChanged,
    super.key,
  });

  final List<FeedPostModel> posts;
  final String currentUserId;
  final bool isLoadingMore;
  final bool hasNextPage;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final void Function(FeedPostModel post)? onPostTap;
  final Future<bool> Function(FeedPostModel post)? onPostDelete;
  final void Function(DateTime? date)? onTopPostDateChanged;
  final void Function(bool isRefreshing)? onRefreshStateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final isLoadingRef = useRef(false);
    final isRefreshingRef = useRef(false);
    final mountedRef = useRef(true);

    useEffect(() {
      mountedRef.value = true;
      return () => mountedRef.value = false;
    }, []);

    // Sort: newest first (index 0 = newest, displayed at bottom in reversed list)
    final sortedPosts = useMemoized(
      () =>
          List<FeedPostModel>.from(posts)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      [posts],
    );

    final sortedPostsRef = useRef<List<FeedPostModel>>([]);
    useEffect(() {
      sortedPostsRef.value = sortedPosts;
      return null;
    }, [sortedPosts]);

    // Scroll handler for pagination + date tracking
    useEffect(() {
      void handler() {
        if (!scrollController.hasClients) return;
        final pos = scrollController.position;

        // Pagination: in reversed list, older posts are at maxScrollExtent
        final distFromOlder = pos.pixels - pos.minScrollExtent;
        // Use maxScrollExtent direction for older posts
        final distFromOlderEdge = pos.maxScrollExtent - pos.pixels;

        if (distFromOlderEdge <= FeedLayout.scrollTriggerDistance * s) {
          if (hasNextPage && !isLoadingMore && !isLoadingRef.value) {
            isLoadingRef.value = true;
            onLoadMore();
            Future.delayed(const Duration(milliseconds: 300), () {
              isLoadingRef.value = false;
            });
          }
        }

        // Date tracking
        final current = sortedPostsRef.value;
        if (current.isNotEmpty && onTopPostDateChanged != null) {
          DateTime topDate;
          if (pos.maxScrollExtent > pos.minScrollExtent) {
            final range = pos.maxScrollExtent - pos.minScrollExtent;
            final progress = (pos.pixels - pos.minScrollExtent) / range;
            final idx = (progress * (current.length - 1))
                .clamp(0.0, current.length - 1.0)
                .round();
            topDate = current[idx].createdAt.toLocal();
          } else {
            topDate = current.first.createdAt.toLocal();
          }
          final cb = onTopPostDateChanged;
          final d = topDate;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mountedRef.value) cb?.call(d);
          });
        }
      }

      scrollController.addListener(handler);
      Future.microtask(() {
        if (scrollController.hasClients) handler();
      });
      return () => scrollController.removeListener(handler);
    }, [scrollController, posts.length]);

    if (posts.isEmpty) {
      return const SizedBox.shrink(); // Empty state handled by parent
    }

    final interPostGap = FeedLayout.authorToNextPostGap * s;

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        // Pull-to-refresh: BouncingScrollPhysics absorbs overscroll,
        // so we detect it via outOfRange + pixels past minScrollExtent.
        if (!scrollController.hasClients || isRefreshingRef.value) {
          return false;
        }
        final metrics = notification.metrics;
        if (!metrics.outOfRange) return false;
        final overscroll = metrics.minScrollExtent - metrics.pixels;
        logger.log(
          'Bounce overscroll: ${overscroll.toStringAsFixed(1)}, '
          'pixels: ${metrics.pixels.toStringAsFixed(1)}',
        );
        if (overscroll > 40) {
          logger.info('Pull-to-refresh triggered');
          isRefreshingRef.value = true;
          onRefreshStateChanged?.call(true);
          onRefresh()
              .then((_) {
                logger.info('Pull-to-refresh complete');
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mountedRef.value) {
                    isRefreshingRef.value = false;
                    onRefreshStateChanged?.call(false);
                  }
                });
              })
              .catchError((_) {
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mountedRef.value) {
                    isRefreshingRef.value = false;
                    onRefreshStateChanged?.call(false);
                  }
                });
              });
        }
        return false;
      },
      child: ListView.separated(
        controller: scrollController,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              FeedLayout.feedBottomPadding * s,
          top: MediaQuery.of(context).padding.top + 50 * s,
        ),
        itemCount: sortedPosts.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: interPostGap),
        itemBuilder: (context, index) {
          if (index == sortedPosts.length) {
            return const SizedBox.shrink();
          }
          final post = sortedPosts[index];
          final isCurrentUser = post.authorId == currentUserId;

          final card = FeedPostCard(
            key: ValueKey('feed_post_${post.id}'),
            post: post,
            isCurrentUser: isCurrentUser,
            onTap: onPostTap != null ? () => onPostTap!(post) : null,
          );

          if (!isCurrentUser || onPostDelete == null) return card;

          return Dismissible(
            key: ValueKey('dismiss_${post.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => onPostDelete!(post),
            background: const SizedBox.shrink(),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 24 * s),
              child: Icon(
                Icons.delete_rounded,
                color: MainColors.dark,
                size: 28 * s,
              ),
            ),
            child: card,
          );
        },
      ),
    );
  }
}
