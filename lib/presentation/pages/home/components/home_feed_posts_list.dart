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
  final Future<void> Function() onRefresh;
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
    // Track if we're currently refreshing from pull-up
    final isRefreshingRef = useRef(false);
    // Track if widget is still mounted to prevent updating disposed state
    final mountedRef = useRef(true);
    
    useEffect(() {
      mountedRef.value = true;
      return () {
        mountedRef.value = false;
      };
    }, []);
    
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
      
      // Detect pull-up refresh at bottom (most recent posts)
      // In reverse ListView, minScrollExtent is at bottom
      // When user is at bottom and tries to scroll further, position stays at minScrollExtent
      // but we can detect this via overscroll notification instead
      // This scroll listener is mainly for pagination
    }

    useEffect(() {
      effectiveScrollController.addListener(onScroll);
      return () => effectiveScrollController.removeListener(onScroll);
    }, [effectiveScrollController]);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      final isRefreshingEmpty = useState(false);

      return NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (effectiveScrollController.hasClients && !isRefreshingEmpty.value && !isLoading) {
            final position = effectiveScrollController.position;
            // In reverse ListView, minScrollExtent is at bottom (most recent posts)
            final isAtBottom = position.pixels <= position.minScrollExtent + 10;
            // Negative scrollDelta means scrolling up (towards newer posts in reversed list)
            final isScrollingUp = notification.scrollDelta! < 0;
            
            if (isAtBottom && isScrollingUp) {
              debugPrint('🔄 Empty state pull-up refresh triggered');
              isRefreshingEmpty.value = true;
              isRefreshingRef.value = true;
              onRefresh().then((_) {
                debugPrint('📦 Empty state refresh Future completed, mounted: ${mountedRef.value}');
                if (mountedRef.value) {
                  debugPrint('✅ Empty state refresh completed');
                  isRefreshingEmpty.value = false;
                  isRefreshingRef.value = false;
                } else {
                  debugPrint('⚠️ Widget disposed, skipping state update');
                }
              }).catchError((error) {
                debugPrint('❌ Empty state refresh error: $error');
                if (mountedRef.value) {
                  isRefreshingEmpty.value = false;
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
                  notification.overscroll.abs() > 30 && // Lower threshold
                  !isRefreshingEmpty.value &&
                  !isLoading) {
                debugPrint('🔄 Empty state overscroll refresh triggered');
                isRefreshingEmpty.value = true;
                isRefreshingRef.value = true;
                onRefresh().then((_) {
                  debugPrint('📦 Empty state overscroll refresh Future completed, mounted: ${mountedRef.value}');
                  if (mountedRef.value) {
                    debugPrint('✅ Empty state overscroll refresh completed');
                    isRefreshingEmpty.value = false;
                    isRefreshingRef.value = false;
                  } else {
                    debugPrint('⚠️ Widget disposed, skipping state update');
                  }
                }).catchError((error) {
                  debugPrint('❌ Empty state overscroll refresh error: $error');
                  if (mountedRef.value) {
                    isRefreshingEmpty.value = false;
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

    final sortedPosts = List<FeedPostModel>.from(posts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRefreshing = useState(false);

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        // Fallback: detect when at bottom and trying to scroll further
        if (effectiveScrollController.hasClients && 
            !isRefreshing.value && 
            !isRefreshingRef.value &&
            !isLoading) {
          final position = effectiveScrollController.position;
          final isAtBottom = position.pixels <= position.minScrollExtent + 5;
          // In reversed list, negative scrollDelta when at bottom means trying to pull up
          final isTryingToPullUp = notification.scrollDelta! < -5;
          
          if (isAtBottom && isTryingToPullUp) {
            debugPrint('🔄 Pull-up refresh triggered at bottom');
            isRefreshing.value = true;
            isRefreshingRef.value = true;
            onRefresh().then((_) {
              debugPrint('📦 Refresh Future completed, mounted: ${mountedRef.value}');
              if (mountedRef.value) {
                debugPrint('✅ Pull-up refresh completed');
                isRefreshing.value = false;
                isRefreshingRef.value = false;
              } else {
                debugPrint('⚠️ Widget disposed, skipping state update');
              }
            }).catchError((error) {
              debugPrint('❌ Pull-up refresh error: $error');
              if (mountedRef.value) {
                isRefreshing.value = false;
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
          if (effectiveScrollController.hasClients && 
              !isRefreshing.value && 
              !isRefreshingRef.value &&
              !isLoading) {
            final position = effectiveScrollController.position;
            // Check if we're at or very close to the bottom
            final isAtBottom = position.pixels <= position.minScrollExtent + 100;
            
            // When at bottom and overscrolling (trying to pull up), trigger refresh
            // Use absolute value to catch overscroll in either direction
            // Lower threshold to make it more sensitive
            if (isAtBottom && notification.overscroll.abs() > 5) {
              debugPrint('🔄 Overscroll refresh triggered at bottom (overscroll: ${notification.overscroll})');
              isRefreshing.value = true;
              isRefreshingRef.value = true;
              onRefresh().then((_) {
                debugPrint('📦 Overscroll refresh Future completed, mounted: ${mountedRef.value}');
                if (mountedRef.value) {
                  debugPrint('✅ Overscroll refresh completed');
                  isRefreshing.value = false;
                  isRefreshingRef.value = false;
                } else {
                  debugPrint('⚠️ Widget disposed, skipping state update');
                }
              }).catchError((error) {
                debugPrint('❌ Overscroll refresh error: $error');
                if (mountedRef.value) {
                  isRefreshing.value = false;
                  isRefreshingRef.value = false;
                }
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
                post: post,
                isCurrentUser: isCurrentUser,
                onTap: onPostTap != null ? () => onPostTap!(post) : null,
              );
            },
          ),
          // Show refresh indicator at the bottom when refreshing
          if (isRefreshing.value)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + feedPostsListBottomPadding + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}
