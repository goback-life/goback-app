import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_app_resume_refresh.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/nfc/data/providers/nfc_service_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart';
import 'package:cloudless/core/features/post/domain/models/feed_item.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/features/onboarding/data/storables/onboarding_completed_storable.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/background_image.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/onboarding/onboarding_overlay.dart';
import 'package:cloudless/presentation/pages/home/components/home_circle_actions_widget.dart';
import 'package:cloudless/presentation/pages/home/components/home_date_badge.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_posts_list.dart';
import 'package:cloudless/presentation/pages/home/components/home_lockout_button.dart';
import 'package:cloudless/presentation/pages/home/components/home_nfc_tag_button.dart';
import 'package:cloudless/presentation/pages/home/components/home_new_posts_banner.dart';
import 'package:cloudless/presentation/pages/home/components/home_scroll_indicator.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/home/hooks/use_home_scroll_state.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/join_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeView extends HookConsumerWidget with MainLayout, HomeLayout {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDismissed = useState(false);
    final onboardingFuture = useMemoized(() async {
      final value = await OnboardingCompletedStorable().tryGet();
      if (value == null) {
        await OnboardingCompletedStorable().set(true);
        await TutorialCompletedStorable().set(true);
        return true;
      }
      return value;
    });
    final onboardingSnapshot = useFuture(onboardingFuture);
    final hasCompletedOnboarding = onboardingSnapshot.data ?? true;

    final currentUserAsync = ref.watch(getCurrentUserProvider);

    final userId = useMemoized(() {
      return currentUserAsync.whenOrNull(
        data: (userResult) =>
            userResult.fold((user) => user.id, (error) => null),
      );
    }, [currentUserAsync]);

    final feedPosts = useFeedPosts(ref, userId: userId ?? '');
    final isRefreshingFeed = useState(false);
    final topPostDate = useState<DateTime?>(null);

    final circleMembersData = useCircleMembers(ref);

    // Scroll state (extracted hook)
    final scrollState = useHomeScrollState(ref, feedPosts: feedPosts);

    // Feed cache preload / periodic cleanup
    _useFeedCacheLifecycle(ref, userId: userId);

    // Check for completed lockout that hasn't been posted yet
    _usePendingLockoutCheck(ref);

    // Refresh data when app resumes from background
    _useAppResumeRefresh(ref, userId: userId);

    // Periodic refresh for new posts (every 60s)
    _usePeriodicFeedRefresh(ref, userId: userId);

    // Periodic notification count refresh (every 60s)
    _usePeriodicNotificationRefresh(ref, userId: userId);

    final showOnboarding =
        !hasCompletedOnboarding && !onboardingDismissed.value;

    final homeContent = MainDataLoader(
      provider: currentUserAsync,
      useScaffold: false,
      onRetry: () => ref.invalidate(getCurrentUserProvider),
      builder: (context, user) {
        final profileAsync = ref.watch(getProfileProvider(user.id));
        if (profileAsync.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasFeedReady =
            feedPosts.posts.isNotEmpty ||
            (!feedPosts.isLoading && feedPosts.posts.isEmpty);
        final hasCircleMembers = circleMembersData.allUsers.isNotEmpty;
        final knowsNoCircleMembers =
            !circleMembersData.isLoading && circleMembersData.allUsers.isEmpty;

        return _buildHomeContent(
          context,
          ref,
          feedPosts,
          userId!,
          hasFeedReady || hasCircleMembers,
          circleMembersData.isLoading,
          knowsNoCircleMembers,
          scrollState,
          isRefreshingFeed,
          topPostDate,
        );
      },
    );

    if (!showOnboarding) return homeContent;

    return Stack(
      children: [
        homeContent,
        OnboardingOverlay(
          onDismiss: () async {
            await OnboardingCompletedStorable().set(true);
            onboardingDismissed.value = true;
          },
        ),
      ],
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
    HomeScrollState scrollState,
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
                    context: context,
                    ref: ref,
                    feedPosts: feedPosts,
                    currentUserId: currentUserId,
                    scrollController: scrollState.scrollController,
                    onPostTap: (post) =>
                        PostDetailPage.show(context, post: post),
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

            if (!scrollState.isAtTop)
              Positioned(
                top:
                    (MediaQuery.of(context).size.height -
                            (topMargin + navBarHeight + titleToImage)) /
                        2 -
                    scrollIndicatorSize / 2,
                right: scrollIndicatorMarginRight,
                child: HomeScrollIndicator(onTap: scrollState.onScrollToBottom),
              ),
            if (!scrollState.isAtTop && feedPosts.newPostsCount > 0)
              Positioned(
                top:
                    (MediaQuery.of(context).size.height -
                            (topMargin + navBarHeight + titleToImage)) /
                        2 -
                    newPostsBannerSize / 2,
                right: newPostsBannerMarginRight,
                child: HomeNewPostsBanner(
                  newPostsCount: feedPosts.newPostsCount,
                  onTap: scrollState.onBannerTap,
                ),
              ),

            Positioned(
              top: dateBadgeTopPadding,
              left: 0,
              right: 0,
              child: Center(
                child: HomeDateBadge(
                  displayDate:
                      topPostDate.value ??
                      (feedPosts.posts.isNotEmpty
                          ? feedPosts.posts
                                .reduce(
                                  (a, b) =>
                                      a.sortTimestamp.isAfter(b.sortTimestamp)
                                      ? a
                                      : b,
                                )
                                .sortTimestamp
                                .toLocal()
                          : null),
                ),
              ),
            ),

            if (showFeed)
              Positioned(
                bottom: bottomMargin + navBarHeight,
                left: horizontalPadding,
                child: const HomeLockoutButton(),
              ),

            if (showFeed)
              Positioned(
                bottom: bottomMargin + navBarHeight,
                right: horizontalPadding,
                child: HomeNfcTagButton(
                  onTagDetected: (venue) {
                    ref
                        .read(manualLockoutNotifierProvider.notifier)
                        .startVenueLockout(venue)
                        .then((_) => router.go(const ManualLockoutRoutable()));
                  },
                  nfcService: ref.read(nfcServiceProvider),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedContent({
    required BuildContext context,
    required WidgetRef ref,
    required FeedPostsResult feedPosts,
    required String currentUserId,
    required ScrollController? scrollController,
    required void Function(FeedPostModel) onPostTap,
    required void Function(bool) onRefreshStateChanged,
    required void Function(DateTime?) onTopPostDateChanged,
  }) {
    if (feedPosts.isLoading && feedPosts.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return HomeFeedPostsList(
      posts: feedPosts.posts,
      currentUserId: currentUserId,
      isLoading: feedPosts.isLoading,
      isLoadingMore: feedPosts.isLoadingMore,
      hasNextPage: feedPosts.hasNextPage,
      onLoadMore: feedPosts.loadMore,
      onRefresh: feedPosts.refresh,
      scrollController: scrollController,
      onPostTap: onPostTap,
      onJoinLockout: (session) => _handleJoinLockout(context, ref, session),
      onRefreshStateChanged: onRefreshStateChanged,
      onTopPostDateChanged: onTopPostDateChanged,
    );
  }

  Future<void> _handleJoinLockout(
    BuildContext context,
    WidgetRef ref,
    LockoutSessionModel session,
  ) async {
    final confirmed = await JoinLockoutDialog.show(context, session);
    if (confirmed != true || !context.mounted) return;

    // Venue (open-ended) lockouts require NFC scan
    if (session.isOpenEnded) {
      final nfcService = ref.read(nfcServiceProvider);
      await nfcService.startReadSession(
        onTagRead: (venue) async {
          if (!context.mounted) return;
          if (session.venueTagId != null &&
              venue.venueId != session.venueTagId) {
            MainSnackbar.showError(
              context,
              'You need to be at the same venue to join this lockout',
            );
            return;
          }
          try {
            await ref
                .read(manualLockoutNotifierProvider.notifier)
                .startVenueLockout(venue);
            if (context.mounted) router.go(const ManualLockoutRoutable());
          } catch (e) {
            if (context.mounted) {
              MainSnackbar.showError(context, 'Failed to start lockout');
            }
          }
        },
        onInvalidTag: () {
          if (context.mounted) {
            MainSnackbar.showError(context, 'This is not a valid GoBack tag');
          }
        },
        onError: () {
          if (context.mounted) {
            MainSnackbar.showError(
              context,
              'NFC scan failed. Please try again.',
            );
          }
        },
      );
      return;
    }

    // Timed lockouts: direct join
    await ref
        .read(manualLockoutNotifierProvider.notifier)
        .joinLockout(session.id);
    if (context.mounted) {
      router.go(const ManualLockoutRoutable());
    }
  }

  Widget _buildCircleActionsContent({
    required bool isLoading,
    required String currentUserId,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: HomeCircleActionsWidget(userId: currentUserId),
    );
  }
}

// ── Private hook-style helpers (called from build, preserve hook order) ──────

void _useFeedCacheLifecycle(WidgetRef ref, {required String? userId}) {
  useEffect(() {
    if (userId != null && userId.isNotEmpty) {
      final cacheNotifier = ref.read(feedPostsCacheProvider.notifier);

      Future.microtask(() {
        if (cacheNotifier.needsFullRebuild) {
          cacheNotifier.fullCacheRebuild(userId);
        } else {
          cacheNotifier.preloadFeed(userId);
        }
      });

      final cleanupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
        cacheNotifier.removeExpiredPosts();
      });

      return cleanupTimer.cancel;
    }
    return null;
  }, [userId]);
}

void _usePendingLockoutCheck(WidgetRef ref) {
  useEffect(() {
    Future<void> check() async {
      final storable = ref.read(manualLockoutStorableProvider);
      final lockoutEnd = await storable.getLockoutEnd();

      if (lockoutEnd != null) {
        // Verify DB session still exists and is active
        final sessionId = await storable.getLockoutSessionId();
        if (sessionId != null && sessionId.isNotEmpty) {
          final sessionService = ref.read(lockoutSessionServiceProvider);
          final stillActive = await sessionService.isSessionStillActive(
            sessionId,
          );
          if (!stillActive) {
            // Session was completed by leader or auto-deleted
            await storable.clearLockout();
            await ref
                .read(manualLockoutNotifierProvider.notifier)
                .clearLockout();
            return; // Don't navigate to lockout page
          }
        }
        router.go(const ManualLockoutRoutable());
      }
    }

    check();
    return null;
  }, []);
}

void _useAppResumeRefresh(WidgetRef ref, {required String? userId}) {
  final lastActiveTime = useRef<DateTime>(DateTime.now());

  useAppResumeRefresh(
    onResume: () async {
      ref.invalidate(getCircleMembersProvider);
      if (userId != null && userId.isNotEmpty) {
        ref.invalidate(unreadNotificationCountProvider(userId: userId));

        final cacheNotifier = ref.read(feedPostsCacheProvider.notifier);
        await cacheNotifier.refresh(userId);
        await cacheNotifier.checkForDeletions(userId);

        final backgroundDuration = DateTime.now().difference(
          lastActiveTime.value,
        );
        if (backgroundDuration > const Duration(hours: 3)) {
          await cacheNotifier.reEnrichCachedPosts();
        }
      }
      lastActiveTime.value = DateTime.now();
    },
  );
}

void _usePeriodicFeedRefresh(WidgetRef ref, {required String? userId}) {
  useEffect(() {
    if (userId != null && userId.isNotEmpty) {
      final timer = Timer.periodic(const Duration(seconds: 60), (_) async {
        final cacheNotifier = ref.read(feedPostsCacheProvider.notifier);
        await cacheNotifier.refresh(userId);
        await cacheNotifier.checkForDeletions(userId);
      });
      return timer.cancel;
    }
    return null;
  }, [userId]);
}

void _usePeriodicNotificationRefresh(WidgetRef ref, {required String? userId}) {
  useEffect(() {
    if (userId != null && userId.isNotEmpty) {
      final timer = Timer.periodic(const Duration(seconds: 60), (_) {
        ref.invalidate(unreadNotificationCountProvider(userId: userId));
      });
      return timer.cancel;
    }
    return null;
  }, [userId]);
}
