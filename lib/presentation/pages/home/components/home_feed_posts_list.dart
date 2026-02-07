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
    
    // Memoize sorted posts to avoid O(n log n) sort on every frame
    final sortedPosts = useMemoized(
      () => List<FeedPostModel>.from(posts)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      [posts],
    );

    // Store sorted posts in ref for scroll handler access without recalculating
    final sortedPostsRef = useRef<List<FeedPostModel>>([]);
    useEffect(() {
      sortedPostsRef.value = sortedPosts;
      return null;
    }, [sortedPosts]);

    // Track scroll velocity for responsive loading
    final lastScrollPosition = useRef<double>(0);
    final lastScrollTime = useRef<DateTime>(DateTime.now());

    useEffect(() {
      void scrollHandler() {
        final position = effectiveScrollController.position;
        final now = DateTime.now();

        // Calculate scroll velocity (pixels per second)
        final timeDelta = now.difference(lastScrollTime.value).inMilliseconds;
        final positionDelta = (position.pixels - lastScrollPosition.value).abs();
        final velocity = timeDelta > 0 ? (positionDelta / timeDelta) * 1000 : 0;

        lastScrollPosition.value = position.pixels;
        lastScrollTime.value = now;

        // In reverse ListView, trigger pagination when scrolling towards older posts (top)
        final distanceFromOlderPostsEdge =
            position.pixels - position.minScrollExtent;

        // Dynamic trigger distance based on scroll velocity
        // Fast scrolling = trigger earlier (up to 3x the normal threshold)
        final velocityMultiplier = (1 + (velocity / 500)).clamp(1.0, 3.0);
        final dynamicTrigger = feedPostsListScrollTrigger * velocityMultiplier;

        if (distanceFromOlderPostsEdge <= dynamicTrigger) {
          if (hasNextPage && !isLoadingMore && !isLoadingRef.value) {
            isLoadingRef.value = true;
            onLoadMore();
            // Reset after a delay to allow the state to update
            Future.delayed(const Duration(milliseconds: 300), () {
              isLoadingRef.value = false;
            });
          }
        }
        
        // Track which post is at the top using memoized sortedPostsRef (no recomputation)
        final currentSorted = sortedPostsRef.value;
        if (currentSorted.isNotEmpty && onTopPostDateChanged != null) {
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
        // Debug: log scroll state occasionally
        if (effectiveScrollController.hasClients) {
          final position = effectiveScrollController.position;
          final isAtBottom = position.pixels <= position.minScrollExtent + 20;
          if (isAtBottom && notification.scrollDelta != null && notification.scrollDelta! < 0) {
            // ignore: avoid_print
            print('[HomeFeedPostsList] ScrollUpdate: pixels=${position.pixels.toStringAsFixed(1)}, min=${position.minScrollExtent.toStringAsFixed(1)}, delta=${notification.scrollDelta}, isRefreshing=${isRefreshingRef.value}, isLoading=$isLoading');
          }
        }

        // Fallback: detect when at bottom and trying to scroll further
        // Remove isLoading check to allow refresh during loading
        if (effectiveScrollController.hasClients &&
            !getIsRefreshing() &&
            !isRefreshingRef.value) {
          final position = effectiveScrollController.position;
          final isAtBottom = position.pixels <= position.minScrollExtent + 20;
          // In reversed list, negative scrollDelta when at bottom means trying to pull up
          final isTryingToPullUp = notification.scrollDelta != null && notification.scrollDelta! < -2;

          if (isAtBottom && isTryingToPullUp) {
            // ignore: avoid_print
            print('[HomeFeedPostsList] Pull-to-refresh triggered via ScrollUpdateNotification');
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
          // Debug: log overscroll
          if (effectiveScrollController.hasClients) {
            final position = effectiveScrollController.position;
            // ignore: avoid_print
            print('[HomeFeedPostsList] Overscroll: ${notification.overscroll.toStringAsFixed(1)}, pixels=${position.pixels.toStringAsFixed(1)}, min=${position.minScrollExtent.toStringAsFixed(1)}, isRefreshing=${isRefreshingRef.value}, isLoading=$isLoading');
          }

          // In reverse ListView, minScrollExtent is at bottom (most recent posts)
          // Remove isLoading check to allow refresh during loading
          if (effectiveScrollController.hasClients &&
              !getIsRefreshing() &&
              !isRefreshingRef.value) {
            final position = effectiveScrollController.position;
            // Check if we're at or very close to the bottom
            final isAtBottom = position.pixels <= position.minScrollExtent + 100;

            // When at bottom and overscrolling (trying to pull down in reversed list), trigger refresh
            // In reversed ListView with BouncingScrollPhysics, NEGATIVE overscroll means
            // trying to go below minScrollExtent (pulling down to refresh)
            if (isAtBottom && notification.overscroll < -5) {
              // ignore: avoid_print
              print('[HomeFeedPostsList] Pull-to-refresh triggered via OverscrollNotification (overscroll: ${notification.overscroll})');
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
