import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_app_resume_refresh.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_published_notifier_provider.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_date_overlay.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_lockout_button.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_new_posts_banner.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_posts_list.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/pages/lockout_complete/lockout_complete_routable.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FeedView extends HookConsumerWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(getCurrentUserProvider);
    final scrollController = useScrollController();
    final screenWidth = MediaQuery.of(context).size.width;

    final isAtBottom = useState(true);
    final hasUserScrolled = useState(false);
    final topPostDate = useState<DateTime?>(null);

    final userId = useMemoized(() {
      return currentUserAsync.whenOrNull(
        data: (r) => r.fold((u) => u.id, (_) => null),
      );
    }, [currentUserAsync]);

    final feedPosts = useFeedPosts(ref, userId: userId ?? '');

    // -- Cache init & periodic cleanup (mirrors HomeView) --
    useEffect(() {
      if (userId != null && userId.isNotEmpty) {
        final cn = ref.read(feedPostsCacheProvider.notifier);
        Future.microtask(() {
          if (cn.needsFullRebuild) {
            cn.fullCacheRebuild(userId);
          } else {
            cn.preloadFeed(userId);
          }
        });
        final t = Timer.periodic(const Duration(minutes: 30), (_) {
          cn.removeExpiredPosts();
        });
        return t.cancel;
      }
      return null;
    }, [userId]);

    // -- Pending lockout check --
    useEffect(() {
      Future<void> check() async {
        final s = ref.read(manualLockoutStorableProvider);
        final end = await s.getLockoutEnd();
        final locked = await s.isLockedOut();
        if (end != null && !locked) {
          final sid = await s.getLockoutSessionId();
          router.go(LockoutCompleteRoutable(lockoutSessionId: sid ?? ''));
        }
      }
      check();
      return null;
    }, []);

    // -- App resume refresh --
    final lastActive = useRef<DateTime>(DateTime.now());
    useAppResumeRefresh(
      onResume: () async {
        ref.invalidate(getCircleMembersProvider);
        if (userId != null && userId.isNotEmpty) {
          ref.invalidate(unreadNotificationCountProvider(userId: userId));
          final cn = ref.read(feedPostsCacheProvider.notifier);
          await cn.refresh(userId);
          await cn.checkForDeletions(userId);
          if (DateTime.now().difference(lastActive.value) >
              const Duration(hours: 3)) {
            await cn.reEnrichCachedPosts();
          }
        }
        lastActive.value = DateTime.now();
      },
    );

    // -- Periodic refresh (60s) --
    useEffect(() {
      if (userId != null && userId.isNotEmpty) {
        final t = Timer.periodic(const Duration(seconds: 60), (_) async {
          final cn = ref.read(feedPostsCacheProvider.notifier);
          await cn.refresh(userId);
          await cn.checkForDeletions(userId);
        });
        return t.cancel;
      }
      return null;
    }, [userId]);

    // -- Notification count polling (60s) --
    useEffect(() {
      if (userId != null && userId.isNotEmpty) {
        final t = Timer.periodic(const Duration(seconds: 60), (_) {
          ref.invalidate(unreadNotificationCountProvider(userId: userId));
        });
        return t.cancel;
      }
      return null;
    }, [userId]);

    // -- Scroll tracking --
    // In this feed, newest is at BOTTOM, reversed ListView means
    // offset 0 = bottom (newest). "at bottom" = offset < 10.
    useEffect(() {
      void onScroll() {
        try {
          if (!scrollController.hasClients) return;
          final atBottom = scrollController.offset < 10;

          if (!atBottom && !hasUserScrolled.value) {
            hasUserScrolled.value = true;
          }
          if (isAtBottom.value != atBottom) {
            isAtBottom.value = atBottom;
            if (atBottom && feedPosts.newPostsCount > 0) {
              feedPosts.loadNewPosts();
            }
            if (atBottom && hasUserScrolled.value) {
              hasUserScrolled.value = false;
            }
          }
        } catch (_) {}
      }

      scrollController.addListener(onScroll);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          if (scrollController.hasClients && scrollController.offset < 10) {
            isAtBottom.value = true;
            hasUserScrolled.value = false;
          }
        } catch (_) {}
      });
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    // Sync isAtBottom when posts length changes
    useEffect(() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          if (scrollController.hasClients && scrollController.offset < 10) {
            if (!isAtBottom.value) {
              isAtBottom.value = true;
              hasUserScrolled.value = false;
            }
          }
        } catch (_) {}
      });
      return null;
    }, [feedPosts.posts.length]);

    // Auto-dismiss banner when at bottom or never scrolled
    useEffect(() {
      final actuallyAtBottom =
          scrollController.hasClients && scrollController.offset < 10;
      if (feedPosts.newPostsCount > 0 &&
          (!actuallyAtBottom || !hasUserScrolled.value)) {
        feedPosts.loadNewPosts();
      }
      return null;
    }, [feedPosts.newPostsCount, isAtBottom.value, hasUserScrolled.value]);

    // -- Auto-scroll on new post created --
    final postActionEvent = ref.watch(postActionNotifierProvider);
    useEffect(() {
      if (postActionEvent != null &&
          postActionEvent.action == PostActionType.create &&
          scrollController.hasClients) {
        scrollController
            .animateTo(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut)
            .then((_) {
          isAtBottom.value = true;
          hasUserScrolled.value = false;
        });
      }
      return null;
    }, [postActionEvent?.timestamp.millisecondsSinceEpoch]);

    final postPublished = ref.watch(postPublishedNotifierProvider);
    useEffect(() {
      if (postPublished != null && scrollController.hasClients) {
        scrollController
            .animateTo(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut)
            .then((_) {
          isAtBottom.value = true;
          hasUserScrolled.value = false;
        });
      }
      return null;
    }, [postPublished?.millisecondsSinceEpoch]);

    // -- Banner / scroll-to-bottom callbacks --
    void onBannerTap() {
      feedPosts.loadNewPosts();
      scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut)
          .then((_) {
        isAtBottom.value = true;
        hasUserScrolled.value = false;
      });
    }

    void onScrollToBottom() {
      scrollController
          .animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut)
          .then((_) {
        isAtBottom.value = true;
        hasUserScrolled.value = false;
      });
    }

    return MainDataLoader(
      provider: currentUserAsync,
      useScaffold: false,
      onRetry: () => ref.invalidate(getCurrentUserProvider),
      builder: (context, user) {
        return _buildStack(
          context,
          ref,
          screenWidth,
          feedPosts,
          user.id,
          scrollController,
          isAtBottom.value,
          topPostDate,
          onBannerTap,
          onScrollToBottom,
        );
      },
    );
  }

  Widget _buildStack(
    BuildContext context,
    WidgetRef ref,
    double screenWidth,
    FeedPostsResult feedPosts,
    String currentUserId,
    ScrollController scrollController,
    bool isAtBottom,
    ValueNotifier<DateTime?> topPostDate,
    VoidCallback onBannerTap,
    VoidCallback onScrollToBottom,
  ) {
    final s = screenWidth / 402.0;
    final safeTop = MediaQuery.of(context).padding.top;
    final lockoutCenterFromBottom = FeedLayout.lockoutBottomDistance * s;

    final showLoading = feedPosts.isLoading && feedPosts.posts.isEmpty;

    return Stack(
      children: [
        // Feed list
        if (showLoading)
          const Center(
            child: CircularProgressIndicator(color: MainColors.white),
          )
        else if (feedPosts.posts.isNotEmpty)
          FeedPostsList(
            posts: feedPosts.posts,
            currentUserId: currentUserId,
            isLoadingMore: feedPosts.isLoadingMore,
            hasNextPage: feedPosts.hasNextPage,
            onLoadMore: feedPosts.loadMore,
            onRefresh: feedPosts.refresh,
            scrollController: scrollController,
            onPostTap: (post) => PostDetailPage.show(context, post: post),
            onTopPostDateChanged: (date) => topPostDate.value = date,
          ),

        // Date overlay
        Positioned(
          top: safeTop + 8 * s,
          left: 0,
          right: 0,
          child: Center(
            child: FeedDateOverlay(
              displayDate: topPostDate.value ??
                  (feedPosts.posts.isNotEmpty
                      ? feedPosts.posts
                          .reduce(
                              (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
                          .createdAt
                          .toLocal()
                      : null),
            ),
          ),
        ),

        // New posts banner / scroll-to-bottom
        if (!isAtBottom)
          Positioned(
            bottom: lockoutCenterFromBottom +
                FeedLayout.bannerAboveLockout * s +
                FeedLayout.bannerHeight * s,
            left: 0,
            right: 0,
            child: Center(
              child: FeedNewPostsBanner(
                newPostsCount: feedPosts.newPostsCount,
                onTap: feedPosts.newPostsCount > 0
                    ? onBannerTap
                    : onScrollToBottom,
              ),
            ),
          ),

        // Lockout button — centered at 96px (scaled) from bottom
        Builder(
          builder: (context) {
            final btnSize = 60 * s;
            final bottomOffset = lockoutCenterFromBottom - btnSize / 2;
            final leftOffset =
                screenWidth / 2 + FeedLayout.lockoutCenterOffsetX * s - btnSize / 2;
            return Positioned(
              bottom: bottomOffset,
              left: leftOffset,
              child: const FeedLockoutButton(),
            );
          },
        ),
      ],
    );
  }
}
