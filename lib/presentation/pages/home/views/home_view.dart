import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_app_resume_refresh.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_published_notifier_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/background_image.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/pages/home/components/home_circle_actions_widget.dart';
import 'package:cloudless/presentation/pages/home/components/home_date_badge.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_posts_list.dart';
import 'package:cloudless/presentation/pages/home/components/home_lockout_button.dart';
import 'package:cloudless/presentation/pages/home/components/home_new_posts_banner.dart';
import 'package:cloudless/presentation/pages/home/components/home_scroll_indicator.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/lockout_complete/lockout_complete_routable.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class HomeView extends HookConsumerWidget with MainLayout, HomeLayout {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(getCurrentUserProvider);
    final scrollController = useScrollController();

    // Initialize isAtTop based on actual scroll position (not always true)
    final isAtTop = useState(
      !scrollController.hasClients || scrollController.offset < 10,
    );

    final isAtBottom = useState(false);

    // Track if user has actively scrolled (to distinguish from initial position)
    final hasUserScrolled = useState(false);

    final userId = useMemoized(() {
      final id = currentUserAsync.whenOrNull(
        data: (userResult) =>
            userResult.fold((user) => user.id, (error) => null),
      );
      return id;
    }, [currentUserAsync]);

    final feedPosts = useFeedPosts(ref, userId: userId ?? '');
    // ignore: avoid_print
    print('[HomeView] feedPosts.posts.length: ${feedPosts.posts.length}, isLoading: ${feedPosts.isLoading}, userId: $userId');
    final isRefreshingFeed = useState(false);
    final topPostDate = useState<DateTime?>(null);

    final circleMembersData = useCircleMembers(ref);

    // Preload feed in background and set up periodic cleanup
    useEffect(() {
      if (userId != null && userId.isNotEmpty) {
        // Preload feed in background for instant access
        ref.read(feedPostsCacheProvider.notifier).preloadFeed(userId);

        // Periodic cleanup of expired posts (every 5 minutes)
        final cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
          ref.read(feedPostsCacheProvider.notifier).removeExpiredPosts();
        });

        return cleanupTimer.cancel;
      }
      return null;
    }, [userId]);

    // Check for completed lockout that hasn't been posted yet
    useEffect(() {
      Future<void> checkPendingLockout() async {
        final storable = ref.read(manualLockoutStorableProvider);
        final lockoutEnd = await storable.getLockoutEnd();
        final isLockedOut = await storable.isLockedOut();

        // If there was a lockout (has end time) and it has ended, redirect to complete screen
        // This handles both cases: with and without sessionId
        if (lockoutEnd != null && !isLockedOut) {
          final sessionId = await storable.getLockoutSessionId();
          router.go(LockoutCompleteRoutable(lockoutSessionId: sessionId ?? ''));
        }
      }
      checkPendingLockout();
      return null;
    }, []);

    // Refresh data when app resumes from background
    // This replaces aggressive polling - data is fetched in parallel on resume
    useAppResumeRefresh(
      onResume: () {
        debugPrint('[HomeView] App resume refresh triggered - invalidating circle members and notifications');
        // Refresh circle members (avatars fetched in parallel)
        ref.invalidate(getCircleMembersProvider);
        // Refresh notification count
        if (userId != null && userId.isNotEmpty) {
          ref.invalidate(unreadNotificationCountProvider(userId: userId));
        }
      },
    );

    // Refresh unread notification count on app resume and with light polling (60s)
    // Push notifications will handle time-critical alerts when implemented
    useEffect(() {
      if (userId != null && userId.isNotEmpty) {
        // Light polling at 60s interval (will be replaced by push notifications later)
        final timer = Timer.periodic(const Duration(seconds: 60), (_) {
          ref.invalidate(unreadNotificationCountProvider(userId: userId));
        });

        return timer.cancel;
      }
      return null;
    }, [userId]);

    // Listen to scroll position
    useEffect(
      () {
        void onScroll() {
          try {
            if (!scrollController.hasClients) return;
            final atTop = scrollController.offset < 10;

            final maxScroll = scrollController.position.maxScrollExtent;
            final currentScroll = scrollController.offset;
            final atBottom = maxScroll - currentScroll < 100;

            // Mark that user has scrolled away from top
            if (!atTop && !hasUserScrolled.value) {
              hasUserScrolled.value = true;
            }

            if (isAtBottom.value != atBottom) {
              isAtBottom.value = atBottom;
            }

            if (isAtTop.value != atTop) {
              isAtTop.value = atTop;

              // If user scrolled to top and there are new posts, reset the counter
              // because they can see the new posts now
              if (atTop && feedPosts.newPostsCount > 0) {
                feedPosts.loadNewPosts(); // This resets the counter
              }

              // Reset hasUserScrolled when user returns to top
              // So that if new posts arrive while at top, banner won't show
              if (atTop && hasUserScrolled.value) {
                hasUserScrolled.value = false;
              }
            }
          } catch (e) {
            // Controller may be attached to multiple scroll views or disposed
            // Ignore the error and skip the update
          }
        }

        void checkScrollPosition() {
          if (scrollController.hasClients) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              try {
                if (scrollController.hasClients && scrollController.offset < 10) {
                  if (!isAtTop.value) {
                    isAtTop.value = true;
                    hasUserScrolled.value = false;
                  }
                }
              } catch (e) {
                // Controller may be attached to multiple scroll views or disposed
                // Ignore the error and skip the update
              }
            });
          }
        }

        scrollController.addListener(onScroll);

        checkScrollPosition();

        return () => scrollController.removeListener(onScroll);
      },
      [scrollController],
    ); // Removed feedPosts.newPostsCount dependency to avoid stale closure

    useEffect(() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          if (scrollController.hasClients) {
            final offset = scrollController.offset;
            if (offset < 10) {
              if (!isAtTop.value) {
                isAtTop.value = true;
                hasUserScrolled.value = false;
              }
            }
          }
        } catch (e) {
          // Controller may be attached to multiple scroll views or disposed
          // Ignore the error and skip the update
        }
      });
      return null;
    }, [feedPosts.posts.length]);

    // Hide banner if new posts arrive while user is NOT at top
    // OR if user has never scrolled (still at initial position)
    useEffect(() {
      // Check actual scroll position, not just isAtTop state
      final actuallyAtTop =
          scrollController.hasClients && scrollController.offset < 10;

      // Hide banner if:
      // 1. User is not at top (scrolled down)
      // 2. OR user has never scrolled (still at initial position after app start/reload)
      if (feedPosts.newPostsCount > 0 &&
          (!actuallyAtTop || !hasUserScrolled.value)) {
        feedPosts.loadNewPosts(); // Silently reset the counter
      }
      return null;
    }, [feedPosts.newPostsCount, isAtTop.value, hasUserScrolled.value]);

    // Listen to post action events to auto-scroll to top ONLY on create (not update)
    final postActionEvent = ref.watch(postActionNotifierProvider);

    useEffect(() {
      if (postActionEvent != null) {
        // Scroll to top ONLY when a new post is created, NOT when updated
        if (postActionEvent.action == PostActionType.create &&
            scrollController.hasClients) {
          scrollController
              .animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              )
              .then((_) {
                isAtTop.value = true;
                hasUserScrolled.value = false;
              });
        }
      }
      return null;
    }, [postActionEvent?.timestamp.millisecondsSinceEpoch]);

    final postPublishedFlag = ref.watch(postPublishedNotifierProvider);

    useEffect(() {
      if (postPublishedFlag != null && scrollController.hasClients) {
        scrollController
            .animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
            .then((_) {
              isAtTop.value = true;
              hasUserScrolled.value = false;
            });
      }
      return null;
    }, [postPublishedFlag?.millisecondsSinceEpoch]);

    void onBannerTap() {
      feedPosts.loadNewPosts();

      scrollController
          .animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            isAtTop.value = true;
            hasUserScrolled.value = false;
          });
    }

    void onScrollToBottom() {
      scrollController
          .animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            isAtTop.value = true;
            hasUserScrolled.value = false;
          });
    }

    return MainDataLoader(
      provider: currentUserAsync,
      useScaffold: false,
      onRetry: () {
        ref.invalidate(getCurrentUserProvider);
      },
      builder: (context, user) {
        final profileAsync = ref.watch(getProfileProvider(user.id));

        // Check if profile is loaded (we need it for empty state)
        final isProfileLoading = profileAsync.isLoading;

        if (isProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Build home content with current data
        // Show feed if it has posts OR if it has finished loading (even if empty)
        // Only show circle actions if we know for sure there are no members (not just if loading)
        final hasFeedReady = feedPosts.posts.isNotEmpty || (!feedPosts.isLoading && feedPosts.posts.isEmpty);
        final hasCircleMembers = circleMembersData.allUsers.isNotEmpty;
        final knowsNoCircleMembers = !circleMembersData.isLoading && circleMembersData.allUsers.isEmpty;
        
        return _buildHomeContent(
          context,
          ref,
          feedPosts,
          userId!,
          hasFeedReady || hasCircleMembers, // Show feed if ready OR if we have members
          circleMembersData.isLoading,
          knowsNoCircleMembers, // Only show circle actions if we know there are no members
          scrollController,
          onBannerTap,
          onScrollToBottom,
          isAtTop.value,
          isAtBottom.value,
          isRefreshingFeed,
          topPostDate,
        );
      },
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    WidgetRef ref,
    FeedPostsResult feedPosts,
    String currentUserId,
    bool showFeed,
    bool circleMembersLoading,
    bool knowsNoCircleMembers,
    ScrollController scrollController,
    VoidCallback onNewPostsBannerTap,
    VoidCallback onScrollToBottom,
    bool isAtTop,
    bool isAtBottom,
    ValueNotifier<bool> isRefreshingFeed,
    ValueNotifier<DateTime?> topPostDate,
  ) {
    return BackgroundImage(
      backgroundImage: Assets.png.background.provider(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            showFeed
                ? _buildFeedContent(
                    feedPosts: feedPosts,
                    currentUserId: currentUserId,
                    scrollController: scrollController,
                    onPostTap: (post) => _navigateToPostDetail(context, post),
                    onRefreshStateChanged: (isRefreshing) {
                      if (isRefreshingFeed.value != isRefreshing) {
                        isRefreshingFeed.value = isRefreshing;
                      }
                    },
                    onTopPostDateChanged: (date) {
                      topPostDate.value = date;
                    },
                  )
                : _buildCircleActionsContent(
                    isLoading: circleMembersLoading && !knowsNoCircleMembers,
                    currentUserId: currentUserId,
                  ),

            if (!isAtTop)
              Positioned(
                top:
                    (MediaQuery.of(context).size.height -
                            (topMargin + navBarHeight + titleToImage)) /
                        2 -
                    scrollIndicatorSize / 2,
                right: scrollIndicatorMarginRight,
                child: HomeScrollIndicator(onTap: onScrollToBottom),
              ),
            if (!isAtTop && feedPosts.newPostsCount > 0)
              Positioned(
                top:
                    (MediaQuery.of(context).size.height -
                            (topMargin + navBarHeight + titleToImage)) /
                        2 -
                    newPostsBannerSize / 2,
                right: newPostsBannerMarginRight,
                child: HomeNewPostsBanner(
                  newPostsCount: feedPosts.newPostsCount,
                  onTap: () {
                    onNewPostsBannerTap();
                  },
                ),
              ),

            Positioned(
              top: dateBadgeTopPadding,
              left: 0,
              right: 0,
              child: Center(
                child: HomeDateBadge(
                  displayDate: topPostDate.value ??
                      (feedPosts.posts.isNotEmpty
                          ? feedPosts.posts
                              .reduce((a, b) =>
                                  a.createdAt.isAfter(b.createdAt) ? a : b)
                              .createdAt
                              .toLocal()
                          : null),
                ),
              ),
            ),

            // Lockout button - bottom left
            // Always show when feed view is active (even if empty) - this is the entry point
            if (showFeed)
              Positioned(
                bottom: bottomMargin + navBarHeight,
                left: horizontalPadding,
                child: const HomeLockoutButton(),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildFeedContent({
    required FeedPostsResult feedPosts,
    required String currentUserId,
    required ScrollController scrollController,
    required void Function(FeedPostModel) onPostTap,
    required void Function(bool) onRefreshStateChanged,
    required void Function(DateTime?) onTopPostDateChanged,
  }) {
    final showLoading = feedPosts.isLoading && feedPosts.posts.isEmpty;

    // ignore: avoid_print
    print('[HomeView._buildFeedContent] posts: ${feedPosts.posts.length}, showLoading: $showLoading');

    if (showLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return HomeFeedPostsList(
      posts: feedPosts.posts,
      currentUserId: currentUserId,
      isLoading: feedPosts.isLoading,
      isLoadingMore: feedPosts.isLoadingMore,
      hasNextPage: feedPosts.hasNextPage,
      onLoadMore: () {
        feedPosts.loadMore();
      },
      onRefresh: feedPosts.refresh,
      scrollController: scrollController,
      onPostTap: onPostTap,
      onRefreshStateChanged: onRefreshStateChanged,
      onTopPostDateChanged: onTopPostDateChanged,
    );
  }

  Widget _buildCircleActionsContent({
    required bool isLoading,
    required String currentUserId,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
      ),
      child: HomeCircleActionsWidget(userId: currentUserId),
    );
  }

  void _navigateToPostDetail(BuildContext context, FeedPostModel post) {
    PostDetailPage.show(context, post: post);
  }
}
