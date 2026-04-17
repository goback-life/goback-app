import 'dart:async';

import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/pending_selection_provider.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_app_resume_refresh.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_item.dart';
import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_published_notifier_provider.dart';
import 'package:cloudless/core/features/share/domain/providers/pending_share_provider.dart';
import 'package:cloudless/presentation/components/share_card/share_post_dialog.dart';
import 'package:cloudless/core/features/onboarding/data/storables/onboarding_completed_storable.dart';
import 'package:cloudless/core/features/onboarding/data/storables/tutorial_completed_storable.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/components/onboarding/onboarding_overlay.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_date_overlay.dart';
import 'package:cloudless/presentation/pages/home/components/memorable_post_selection_dialog.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_circle_hub_button.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_lockout_button.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_new_posts_banner.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_onboarding_prompt.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_posts_list.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/join_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_routable.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/core/features/post/domain/providers/delete_post_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FeedView extends HookConsumerWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Onboarding overlay — shown once per storable version.
    // tryGet() returns null if the key was never set (existing user before
    // onboarding was added) vs false (new user who just created profile).
    final onboardingDismissed = useState(false);
    final onboardingFuture = useMemoized(() async {
      final value = await OnboardingCompletedStorable().tryGet();
      if (value == null) {
        // Existing user — auto-complete onboarding & tutorial
        await OnboardingCompletedStorable().set(true);
        await TutorialCompletedStorable().set(true);
        return true;
      }
      return value;
    });
    final onboardingSnapshot = useFuture(onboardingFuture);
    final hasCompletedOnboarding = onboardingSnapshot.data ?? true;
    final showOnboarding =
        !hasCompletedOnboarding && !onboardingDismissed.value;

    // Tutorial check — redirect after onboarding is done
    final tutorialFuture = useMemoized(() async {
      final value = await TutorialCompletedStorable().tryGet();
      return value ?? true; // null = existing user, skip tutorial
    });
    final tutorialSnapshot = useFuture(tutorialFuture);
    final hasCompletedTutorial = tutorialSnapshot.data ?? true;

    useEffect(() {
      if (hasCompletedOnboarding && !hasCompletedTutorial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go(const TutorialRoutable());
        });
      }
      return null;
    }, [hasCompletedOnboarding, hasCompletedTutorial]);

    final currentUserAsync = ref.watch(getCurrentUserProvider);
    final scrollController = useScrollController();
    final screenWidth = MediaQuery.of(context).size.width;

    final isAtBottom = useState(true);
    final hasUserScrolled = useState(false);
    final isFarFromBottom = useState(false); // true after scrolling ~4 posts
    final topPostDate = useState<DateTime?>(null);
    final isRefreshing = useState(false);

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
        if (end != null) {
          router.go(const ManualLockoutRoutable());
        }
      }

      check();
      return null;
    }, []);

    // -- Pending share dialog (deferred from post creation) --
    final pendingShare = ref.watch(pendingShareProvider);
    useEffect(() {
      if (pendingShare != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          ref.read(pendingShareProvider.notifier).state = null;
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (context.mounted) {
            await SharePostDialog.show(
              context,
              ref,
              lockoutId: pendingShare.lockoutId,
              authorId: pendingShare.authorId,
              imagePath: pendingShare.imagePath,
              description: pendingShare.description,
            );
          }
        });
      }
      return null;
    }, [pendingShare]);

    // -- Memorable post selection prompt --
    useEffect(() {
      Future<void> checkMemorableSelection() async {
        final shouldShow = await ref.read(
          shouldShowMemorableSelectionProvider.future,
        );
        if (shouldShow && context.mounted) {
          MemorablePostSelectionDialog.show(context);
        }
      }

      checkMemorableSelection();
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
          final offset = scrollController.offset;
          final atBottom = offset < 10;

          // ~4 posts worth of scroll distance (squircle + gaps, scaled)
          final fourPostThreshold =
              4 * (250 + 15 + 39 + 18) * (screenWidth / 402.0);
          final farEnough = offset > fourPostThreshold;
          if (isFarFromBottom.value != farEnough) {
            isFarFromBottom.value = farEnough;
          }

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
            .animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
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
            .animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
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
          .animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            isAtBottom.value = true;
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
            isAtBottom.value = true;
            hasUserScrolled.value = false;
          });
    }

    final feedContent = MainDataLoader(
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
          isFarFromBottom.value,
          isRefreshing,
          topPostDate,
          onBannerTap,
          onScrollToBottom,
        );
      },
    );

    if (!showOnboarding) return feedContent;

    return Stack(
      children: [
        feedContent,
        OnboardingOverlay(
          onDismiss: () async {
            await OnboardingCompletedStorable().set(true);
            onboardingDismissed.value = true;
            final tutorialDone = await TutorialCompletedStorable().get(
              defaultValue: false,
            );
            if (!tutorialDone) {
              router.go(const TutorialRoutable());
            }
          },
        ),
      ],
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
    bool isFarFromBottom,
    ValueNotifier<bool> isRefreshing,
    ValueNotifier<DateTime?> topPostDate,
    VoidCallback onBannerTap,
    VoidCallback onScrollToBottom,
  ) {
    final s = screenWidth / 402.0;
    final safeTop = MediaQuery.of(context).padding.top;
    final lockoutCenterFromBottom = FeedLayout.lockoutBottomDistance * s;

    final showLoading = feedPosts.isLoading && feedPosts.posts.isEmpty;
    final circleMembersAsync = ref.watch(getCircleMembersProvider);
    final circleMembers = circleMembersAsync.maybeWhen(
      data: (r) =>
          r.fold((members) => members, (_) => <ConnectionMemberModel>[]),
      orElse: () => <ConnectionMemberModel>[],
    );
    final circleMembersLoaded = circleMembersAsync.hasValue;
    final hasUnread = ref
        .watch(unreadNotificationCountProvider(userId: currentUserId))
        .maybeWhen(
          data: (r) => r.fold((c) => c > 0, (_) => false),
          orElse: () => false,
        );
    final hasIncomingRequests = ref
        .watch(getIncomingRequestsProvider)
        .maybeWhen(
          data: (r) => r.fold((list) => list.isNotEmpty, (_) => false),
          orElse: () => false,
        );

    Future<void> handleJoinLockout(
      BuildContext ctx,
      WidgetRef widgetRef,
      LockoutSessionModel session,
    ) async {
      final confirmed = await JoinLockoutDialog.show(ctx, session);
      if (confirmed == true) {
        await widgetRef
            .read(manualLockoutNotifierProvider.notifier)
            .joinLockout(session.id);
        if (ctx.mounted) {
          router.go(const ManualLockoutRoutable());
        }
      }
    }

    return Stack(
      children: [
        // Feed list
        if (showLoading)
          Center(child: CircularProgressIndicator(color: MainColors.dark))
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
            onPostDelete: (post) => _confirmAndDeletePost(
              context,
              ref,
              post: post,
              currentUserId: currentUserId,
            ),
            onJoinLockout: (session) =>
                handleJoinLockout(context, ref, session),
            onTopPostDateChanged: (date) => topPostDate.value = date,
            onRefreshStateChanged: (v) => isRefreshing.value = v,
          ),

        // Date overlay
        Positioned(
          top: safeTop + 8 * s,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: FeedDateOverlay(
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
                hasUnreadNotifications: hasUnread,
                postCount: feedPosts.posts.length,
              ),
            ),
          ),
        ),

        // Circle hub button — top right, aligned with date overlay
        Positioned(
          top: safeTop + 8 * s,
          right: FeedLayout.circleHubButtonRight * s,
          child: FeedCircleHubButton(
            hasUnread: hasUnread || hasIncomingRequests,
          ),
        ),

        // New posts banner / scroll-to-bottom — below date overlay
        if (!isAtBottom && (isFarFromBottom || feedPosts.newPostsCount > 0))
          Positioned(
            top: safeTop + 8 * s + 36 * s + 12 * s,
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

        // Onboarding prompt — fixed below date row until 4 friends added
        if (circleMembersLoaded && circleMembers.length < 4)
          Positioned(
            top: safeTop + 8 * s + 36 * s + 12 * s,
            left: 20 * s,
            right: 20 * s,
            child: FeedOnboardingPrompt(friends: circleMembers),
          ),

        // Lockout button — centered at 96px (scaled) from bottom
        Builder(
          builder: (context) {
            final btnW = 86 * s;
            final btnH = 102 * s;
            final bottomOffset = lockoutCenterFromBottom - btnH / 2;
            final leftOffset =
                screenWidth / 2 +
                FeedLayout.lockoutCenterOffsetX * s -
                btnW / 2;
            return Positioned(
              bottom: bottomOffset,
              left: leftOffset,
              child: FeedLockoutButton(isRefreshing: isRefreshing.value),
            );
          },
        ),
      ],
    );
  }

  /// Shows a confirmation dialog and deletes the post if confirmed.
  /// Returns true if deleted (Dismissible animates away), false otherwise.
  Future<bool> _confirmAndDeletePost(
    BuildContext context,
    WidgetRef ref, {
    required FeedPostModel post,
    required String currentUserId,
  }) async {
    debugPrint('[FeedDelete] START postId=${post.id} userId=$currentUserId');

    // Step 1: Show confirmation dialog and wait for user choice.
    final confirmed = Completer<bool>();

    try {
      debugPrint('[FeedDelete] Showing dialog...');
      await MainAlert.showFull(
        context: context,
        title: translator.translate('components.delete_post.title'),
        content: Text(
          translator.translate('components.delete_post.content'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          textAlign: TextAlign.center,
        ),
        primaryButtonText: translator.translate(
          'components.delete_post.confirm',
        ),
        secondaryButtonText: translator.translate(
          'components.delete_post.cancel',
        ),
        primaryButtonType: CallToActionType.danger,
        onPrimaryPressed: () {
          debugPrint('[FeedDelete] Delete button tapped');
          router.pop();
          confirmed.complete(true);
        },
        onSecondaryPressed: () {
          debugPrint('[FeedDelete] Cancel button tapped');
          router.pop();
          confirmed.complete(false);
        },
      );
      debugPrint('[FeedDelete] Dialog resolved');
    } catch (e, s) {
      debugPrint('[FeedDelete] Dialog THREW: $e\n$s');
      return false;
    }

    if (!await confirmed.future) {
      debugPrint('[FeedDelete] User cancelled');
      return false;
    }

    // Step 2: Execute deletion outside the callback so exceptions propagate.
    debugPrint('[FeedDelete] Confirmed. Calling deletePostProvider...');
    try {
      final result = await ref.read(
        deletePostProvider(postId: post.id, authorId: currentUserId).future,
      );

      debugPrint('[FeedDelete] Provider returned: $result');

      return result.fold(
        (_) {
          debugPrint('[FeedDelete] SUCCESS — removing from cache');
          // Direct cache removal for immediate UI update.
          ref.read(feedPostsCacheProvider.notifier).removePost(post.id);
          // Also notify for other listeners (calendar, etc).
          ref
              .read(postActionNotifierProvider.notifier)
              .notifyPostDeleted(postId: post.id);
          return false;
        },
        (error) {
          debugPrint('[FeedDelete] FAILURE (Result.failure): $error');
          if (context.mounted) {
            MainAlert.showError(
              context: context,
              title: translator.translate('components.delete_post.error_title'),
              content: translator.translate(
                'components.delete_post.error_content',
              ),
            );
          }
          return false;
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[FeedDelete] EXCEPTION: $e\n$stackTrace');
      if (context.mounted) {
        await MainAlert.showError(
          context: context,
          title: translator.translate('components.delete_post.error_title'),
          content: translator.translate('components.delete_post.error_content'),
        );
      }
      return false;
    }
  }
}
