import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/use_feed_posts.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_published_notifier_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef HomeScrollState = ({
  bool isAtTop,
  bool isAtBottom,
  ScrollController? scrollController,
  VoidCallback onBannerTap,
  VoidCallback onScrollToBottom,
});

/// Manages scroll position tracking, new-post banner visibility,
/// and auto-scroll on post creation for the home feed.
HomeScrollState useHomeScrollState(
  WidgetRef ref, {
  required FeedPostsResult feedPosts,
}) {
  final scrollController = useScrollController();

  final isAtTop = useState(
    !scrollController.hasClients || scrollController.offset < 10,
  );
  final isAtBottom = useState(false);
  final hasUserScrolled = useState(false);

  // ── Scroll position listener ──────────────────────────────────────────
  useEffect(() {
    void onScroll() {
      try {
        if (!scrollController.hasClients) return;
        final atTop = scrollController.offset < 10;

        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.offset;
        final atBottom = maxScroll - currentScroll < 100;

        if (!atTop && !hasUserScrolled.value) {
          hasUserScrolled.value = true;
        }

        if (isAtBottom.value != atBottom) {
          isAtBottom.value = atBottom;
        }

        if (isAtTop.value != atTop) {
          isAtTop.value = atTop;

          if (atTop && feedPosts.newPostsCount > 0) {
            feedPosts.loadNewPosts();
          }
          if (atTop && hasUserScrolled.value) {
            hasUserScrolled.value = false;
          }
        }
      } catch (e) {
        // Controller may be disposed; ignore.
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
            // ignore
          }
        });
      }
    }

    scrollController.addListener(onScroll);
    checkScrollPosition();
    return () => scrollController.removeListener(onScroll);
  }, [scrollController]);

  // ── Re-check position when posts list length changes ──────────────────
  useEffect(() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        if (scrollController.hasClients && scrollController.offset < 10) {
          if (!isAtTop.value) {
            isAtTop.value = true;
            hasUserScrolled.value = false;
          }
        }
      } catch (e) {
        // ignore
      }
    });
    return null;
  }, [feedPosts.posts.length]);

  // ── Auto-dismiss banner when at top or never scrolled ─────────────────
  useEffect(() {
    final actuallyAtTop =
        scrollController.hasClients && scrollController.offset < 10;
    if (feedPosts.newPostsCount > 0 &&
        (!actuallyAtTop || !hasUserScrolled.value)) {
      feedPosts.loadNewPosts();
    }
    return null;
  }, [feedPosts.newPostsCount, isAtTop.value, hasUserScrolled.value]);

  // ── Auto-scroll to top on new post creation ───────────────────────────
  final postActionEvent = ref.watch(postActionNotifierProvider);

  useEffect(() {
    if (postActionEvent != null &&
        postActionEvent.action == PostActionType.create &&
        scrollController.hasClients) {
      _animateToTop(scrollController, isAtTop, hasUserScrolled);
    }
    return null;
  }, [postActionEvent?.timestamp.millisecondsSinceEpoch]);

  final postPublishedFlag = ref.watch(postPublishedNotifierProvider);

  useEffect(() {
    if (postPublishedFlag != null && scrollController.hasClients) {
      _animateToTop(scrollController, isAtTop, hasUserScrolled);
    }
    return null;
  }, [postPublishedFlag?.millisecondsSinceEpoch]);

  // ── Callbacks ─────────────────────────────────────────────────────────
  void onBannerTap() {
    feedPosts.loadNewPosts();
    _animateToTop(scrollController, isAtTop, hasUserScrolled);
  }

  void onScrollToBottom() {
    _animateToTop(scrollController, isAtTop, hasUserScrolled);
  }

  return (
    isAtTop: isAtTop.value,
    isAtBottom: isAtBottom.value,
    scrollController: scrollController,
    onBannerTap: onBannerTap,
    onScrollToBottom: onScrollToBottom,
  );
}

void _animateToTop(
  ScrollController controller,
  ValueNotifier<bool> isAtTop,
  ValueNotifier<bool> hasUserScrolled,
) {
  controller
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
