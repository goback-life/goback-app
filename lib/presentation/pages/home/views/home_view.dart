import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation_initialization.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_published_notifier_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/background_image.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/pages/home/components/home_circle_actions_widget.dart';
import 'package:cloudless/presentation/pages/home/components/home_create_content_button.dart';
import 'package:cloudless/presentation/pages/home/components/home_date_badge.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_posts_list.dart';
import 'package:cloudless/presentation/pages/home/components/home_new_posts_banner.dart';
import 'package:cloudless/presentation/pages/home/components/home_scroll_indicator.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class HomeView extends HookConsumerWidget with MainLayout, HomeLayout {
  const HomeView({super.key, this.loadingNotifier});

  final ValueNotifier<bool>? loadingNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(getCurrentUserProvider);
    final postCreationInitialization = usePostCreationInitialization(
      ref,
      loadingNotifier: loadingNotifier,
    );
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

    final circleMembersData = useCircleMembers(ref);

    // Polling: Refresh circle members (start after initial load completes)
    useEffect(() {
      print('[HomeView] Polling useEffect evaluated');
      print('[HomeView] circleMembersData.isLoading: ${circleMembersData.isLoading}');
      print('[HomeView] circleMembersData.allUsers.length: ${circleMembersData.allUsers.length}');
      print('[HomeView] Polling condition: !isLoading=${!circleMembersData.isLoading} && isNotEmpty=${circleMembersData.allUsers.isNotEmpty}');
      
      // Wait for initial load to complete before starting polling
      if (!circleMembersData.isLoading && circleMembersData.allUsers.isNotEmpty) {
        print('[HomeView] ✅ Starting polling timer (15s interval)');
        final timer = Timer.periodic(const Duration(seconds: 15), (_) {
          print('[HomeView] Polling timer triggered - invalidating provider');
          ref.invalidate(getCircleMembersProvider);
        });

        return timer.cancel;
      } else {
        print('[HomeView] ❌ Polling NOT started - condition not met');
      }
      return null;
    }, [circleMembersData.isLoading, circleMembersData.allUsers.isNotEmpty]);

    // Listen to scroll position
    useEffect(
      () {
        void onScroll() {
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
        }

        void checkScrollPosition() {
          if (scrollController.hasClients) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients && scrollController.offset < 10) {
                if (!isAtTop.value) {
                  isAtTop.value = true;
                  hasUserScrolled.value = false;
                }
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
        if (scrollController.hasClients && scrollController.offset < 10) {
          if (!isAtTop.value) {
            isAtTop.value = true;
            hasUserScrolled.value = false;
          }
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
          postCreationInitialization,
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
        );
      },
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    WidgetRef ref,
    PostCreationInitializationResult postCreationInit,
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
                    postCreationInit: postCreationInit,
                    scrollController: scrollController,
                    onPostTap: (post) => _navigateToPostDetail(context, post),
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
              child: const Center(child: HomeDateBadge()),
            ),
          ],
        ),
        floatingActionButton: showFeed && feedPosts.posts.isNotEmpty
            ? HomeCreateContentButton(
                onPressed: () {
                  postCreationInit.selectMainImage();
                },
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildFeedContent({
    required FeedPostsResult feedPosts,
    required String currentUserId,
    required PostCreationInitializationResult postCreationInit,
    required ScrollController scrollController,
    required void Function(FeedPostModel) onPostTap,
  }) {
    final showLoading = feedPosts.isLoading && feedPosts.posts.isEmpty;
    
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
      onCreatePost: () {
        postCreationInit.selectMainImage();
      },
      scrollController: scrollController,
      onPostTap: onPostTap,
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
