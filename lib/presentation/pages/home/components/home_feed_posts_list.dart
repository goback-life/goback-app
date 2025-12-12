import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_empty_state.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_post_card.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class HomeFeedPostsList extends HookConsumerWidget with MainLayout, HomeLayout {
  const HomeFeedPostsList({
    required this.posts,
    required this.currentUserId,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasNextPage,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onCreatePost,
    this.scrollController,
    this.onPostTap,
    super.key,
  });

  final List<FeedPostModel> posts;
  final String currentUserId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasNextPage;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;
  final VoidCallback onCreatePost;
  final ScrollController? scrollController;
  final void Function(FeedPostModel post)? onPostTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internalScrollController = useScrollController();
    final effectiveScrollController =
        scrollController ?? internalScrollController;

    // Track if we're currently loading to avoid multiple simultaneous requests
    final isLoadingRef = useRef(false);
    void onScroll() {
      // In reverse ListView, trigger pagination when scrolling towards older posts (top)
      final position = effectiveScrollController.position;
      final distanceFromOlderPostsEdge =
          position.pixels - position.minScrollExtent;

      if (distanceFromOlderPostsEdge <= feedPostsListScrollTrigger) {
        if (hasNextPage && !isLoadingMore && !isLoadingRef.value) {
          isLoadingRef.value = true;
          onLoadMore();
          // Reset after a delay to allow the state to update
          Future.delayed(const Duration(milliseconds: 500), () {
            isLoadingRef.value = false;
          });
        }
      }
    }

    useEffect(() {
      effectiveScrollController.addListener(onScroll);
      return () => effectiveScrollController.removeListener(onScroll);
    }, [effectiveScrollController]);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: const HomeFeedEmptyState(),
        ),
      );
    }

    final sortedPosts = List<FeedPostModel>.from(posts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      controller: effectiveScrollController,
      reverse: true,
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).padding.bottom + feedPostsListBottomPadding,
      ),
      itemCount: sortedPosts.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sortedPosts.length) {
          return const SizedBox.shrink();
        }

        final post = sortedPosts[index];
        final isCurrentUser = post.authorId == currentUserId;

        return HomeFeedPostCard(
          post: post,
          isCurrentUser: isCurrentUser,
          onTap: onPostTap != null ? () => onPostTap!(post) : null,
        );
      },
    );
  }
}
