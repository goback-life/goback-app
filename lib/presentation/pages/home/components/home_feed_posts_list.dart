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
    this.scrollController,
    this.onPostTap,
    this.onRefreshStateChanged,
    this.onTopPostDateChanged,
    super.key,
  });

  final List<FeedPostModel> posts;
  final String currentUserId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasNextPage;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final ScrollController? scrollController;
  final void Function(FeedPostModel post)? onPostTap;
  final void Function(bool isRefreshing)? onRefreshStateChanged;
  final void Function(DateTime? date)? onTopPostDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: avoid_print
    print('[HomeFeedPostsList] build called with ${posts.length} posts, isLoading: $isLoading');
    final internalScrollController = useScrollController();
    final effectiveScrollController =
        scrollController ?? internalScrollController;

    // Track if we're currently loading to avoid multiple simultaneous requests
    final isLoadingRef = useRef(false);
    // Track if we're currently refreshing from pull-up
    final isRefreshingRef = useRef(false);
    // Track if widget is still mounted to prevent updating disposed state
    final mountedRef = useRef(true);
    // Track if we're refreshing when posts are empty (must be outside conditional for hook order)
    final isRefreshingEmptyRef = useRef(false);
    
    useEffect(() {
      mountedRef.value = true;
      return () {
        mountedRef.value = false;
      };
    }, []);
    
    // Sort posts once for use in ListView (computed here for the ListView)
    final sortedPosts = List<FeedPostModel>.from(posts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    useEffect(() {
      void scrollHandler() {
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
        
        // Track which post is at the top - compute from posts parameter directly to avoid capturing sortedPosts
        // This recomputes on each scroll but avoids serialization issues
        if (posts.isNotEmpty && onTopPostDateChanged != null) {
          // Recompute sorted posts inside handler to avoid capturing from outer scope
          final currentSorted = List<FeedPostModel>.from(posts)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          DateTime topPostDate;
          if (position.maxScrollExtent > position.minScrollExtent) {
            // Calculate scroll progress (0 = at bottom/newest, 1 = at top/oldest)
            final scrollRange = position.maxScrollExtent - position.minScrollExtent;
            final scrollProgress = (position.pixels - position.minScrollExtent) / scrollRange;
            // Map to post index (0 = newest, last = oldest)
            final topIndex = (scrollProgress * (currentSorted.length - 1)).clamp(0.0, currentSorted.length - 1.0).round();
            topPostDate = currentSorted[topIndex].createdAt.toLocal();
          } else {
            topPostDate = currentSorted.first.createdAt.toLocal();
          }
          
          // Extract to primitives before creating any closures
          final callback = onTopPostDateChanged;
          final date = topPostDate;
          // Use postFrameCallback to defer and avoid serialization during ValueNotifier updates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callback?.call(date);
          });
        }
      }

      effectiveScrollController.addListener(scrollHandler);
      // Trigger initial calculation after first frame
      Future.microtask(() {
        if (effectiveScrollController.hasClients) {
          scrollHandler();
        }
      });
      return () => effectiveScrollController.removeListener(scrollHandler);
    }, [effectiveScrollController, posts.length]);

    // Only show loading indicator on initial load (when posts are empty)
    // During refresh, keep existing posts visible
    if (isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (effectiveScrollController.hasClients && !isRefreshingEmptyRef.value && !isLoading) {
            final position = effectiveScrollController.position;
            // In reverse ListView, minScrollExtent is at bottom (most recent posts)
            final isAtBottom = position.pixels <= position.minScrollExtent + 10;
            // Negative scrollDelta means scrolling up (towards newer posts in reversed list)
            final isScrollingUp = notification.scrollDelta! < 0;
            
            if (isAtBottom && isScrollingUp) {
              isRefreshingEmptyRef.value = true;
              isRefreshingRef.value = true;
              onRefresh().then((_) {
                if (mountedRef.value) {
                  isRefreshingEmptyRef.value = false;
                  isRefreshingRef.value = false;
                }
              }).catchError((error) {
                if (mountedRef.value) {
                  isRefreshingEmptyRef.value = false;
                  isRefreshingRef.value = false;
                }
              });
            }
          }
          return false;
        },
        child: NotificationListener<OverscrollNotification>(
          onNotification: (notification) {
            // In reverse ListView, minScrollExtent is at bottom (most recent posts)
            // Positive overscroll means trying to scroll beyond minScrollExtent (pull up)
            if (effectiveScrollController.hasClients) {
              final position = effectiveScrollController.position;
              final isAtBottom = position.pixels <= position.minScrollExtent + 20;
              
              if (isAtBottom &&
                  notification.overscroll.abs() > 30 &&
                  !isRefreshingEmptyRef.value &&
                  !isLoading) {
                isRefreshingEmptyRef.value = true;
                isRefreshingRef.value = true;
                onRefresh().then((_) {
                  if (mountedRef.value) {
                    isRefreshingEmptyRef.value = false;
                    isRefreshingRef.value = false;
                  }
                }).catchError((error) {
                  if (mountedRef.value) {
                    isRefreshingEmptyRef.value = false;
                    isRefreshingRef.value = false;
                  }
                });
              }
            }
            return false;
          },
        child: SingleChildScrollView(
            controller: effectiveScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: const HomeFeedEmptyState(),
                ),
              ),
            ),
          ),
        ),
      );
    }


    // Track refresh state for parent callback (use ref to avoid ValueNotifier disposal issues)
    final isRefreshingStateRef = useRef(false);
    
    // Helper to safely update refresh state and notify parent
    void setRefreshing(bool value) {
      if (!mountedRef.value) return;
      if (isRefreshingStateRef.value == value) return;
      isRefreshingStateRef.value = value;
      onRefreshStateChanged?.call(value);
    }
    
    // Helper to safely check refresh state
    bool getIsRefreshing() {
      if (!mountedRef.value) return false;
      return isRefreshingStateRef.value;
    }

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        // Fallback: detect when at bottom and trying to scroll further
        if (effectiveScrollController.hasClients && 
            !getIsRefreshing() && 
            !isRefreshingRef.value &&
            !isLoading) {
          final position = effectiveScrollController.position;
          final isAtBottom = position.pixels <= position.minScrollExtent + 5;
          // In reversed list, negative scrollDelta when at bottom means trying to pull up
          final isTryingToPullUp = notification.scrollDelta! < -5;
          
          if (isAtBottom && isTryingToPullUp) {
            isRefreshingRef.value = true;
            setRefreshing(true);
            onRefresh().then((_) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mountedRef.value) {
                  isRefreshingRef.value = false;
                  setRefreshing(false);
                }
              });
            }).catchError((error) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mountedRef.value) {
                  isRefreshingRef.value = false;
                  setRefreshing(false);
                }
              });
            });
          }
        }
        return false;
      },
      child: NotificationListener<OverscrollNotification>(
        onNotification: (notification) {
          // In reverse ListView, minScrollExtent is at bottom (most recent posts)
          if (effectiveScrollController.hasClients && 
              !getIsRefreshing() && 
              !isRefreshingRef.value &&
              !isLoading) {
            final position = effectiveScrollController.position;
            // Check if we're at or very close to the bottom
            final isAtBottom = position.pixels <= position.minScrollExtent + 100;
            
            // When at bottom and overscrolling (trying to pull up), trigger refresh
            // Use absolute value to catch overscroll in either direction
            // Lower threshold to make it more sensitive
            if (isAtBottom && notification.overscroll.abs() > 5) {
              isRefreshingRef.value = true;
              setRefreshing(true);
              onRefresh().then((_) {
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mountedRef.value) {
                    isRefreshingRef.value = false;
                    setRefreshing(false);
                  }
                });
              }).catchError((error) {
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mountedRef.value) {
                    isRefreshingRef.value = false;
                    setRefreshing(false);
                  }
                });
              });
            }
          }
          return false;
        },
      child: Stack(
        children: [
          ListView.builder(
              controller: effectiveScrollController,
              reverse: true,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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
                  key: ValueKey('post_${post.id}'),
                  post: post,
                  isCurrentUser: isCurrentUser,
                  onTap: onPostTap != null ? () => onPostTap!(post) : null,
                );
              },
            ),
        ],
      ),
      ),
    );
  }
}
