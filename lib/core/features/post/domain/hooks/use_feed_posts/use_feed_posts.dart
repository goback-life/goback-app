import 'dart:async';

import 'package:cloudless/core/features/post/domain/enums/post_action_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/feed_posts_actions.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_feed_posts/feed_posts_polling.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_polling_controller.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_published_notifier_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

typedef FeedPostsResult = ({
  List<FeedPostModel> posts,
  bool isLoading,
  bool isLoadingMore,
  bool hasNextPage,
  int newPostsCount,
  String? errorMessage,
  VoidCallback loadMore,
  Future<void> Function() refresh,
  VoidCallback loadNewPosts,
});

/// Custom hook for managing feed posts with polling, pagination, and real-time updates.
FeedPostsResult useFeedPosts(
  WidgetRef ref, {
  required String userId,
  DateTime? targetDate,
}) {
  final effectiveTargetDate = useMemoized(() => targetDate ?? DateTime.now(), [
    targetDate?.millisecondsSinceEpoch,
  ]);

  final posts = useState<List<FeedPostModel>>([]);
  final isLoading = useState<bool>(false);
  final isLoadingMore = useState<bool>(false);
  final hasNextPage = useState<bool>(true);
  final errorMessage = useState<String?>(null);
  final newPostsCount = useState<int>(0);

  // Cursor-based pagination
  final newestPostTimestamp = useState<DateTime?>(null);
  final oldestPostTimestamp = useState<DateTime?>(null);

  // State management
  final isMounted = useRef(true);
  final hasInitialized = useRef(false);
  final lastUserId = useRef<String?>(null);
  final lastTargetDate = useRef<DateTime?>(null);
  final savedUserId = useRef<String>('');

  Future<void> loadNewPosts() async {
    if (newPostsCount.value > 0) {
      newPostsCount.value = 0;
    }
  }

  final pollingController = usePollingController(
    onPoll: () => FeedPostsPolling.checkForNewPosts(
      ref: ref,
      userId: userId,
      posts: posts,
      newestPostTimestamp: newestPostTimestamp,
      newPostsCount: newPostsCount,
    ),
    interval: const Duration(seconds: 15),
  );

  final updatePollingController = usePollingController(
    onPoll: () => FeedPostsPolling.checkForPostUpdates(
      ref: ref,
      userId: userId,
      posts: posts,
    ),
    interval: const Duration(seconds: 15),
  );

  useEffect(() {
    return () {
      pollingController.stopPolling();
      updatePollingController.stopPolling();
    };
  }, []);

  final postPublishedFlag = ref.watch(postPublishedNotifierProvider);
  final postActionEvent = ref.watch(postActionNotifierProvider);

  useEffect(
    () {
      isMounted.value = true;

      final hasPublishedPost = postPublishedFlag != null;

      ref
        ..listen(postActionNotifierProvider, (previous, next) {
          if (next != null &&
              userId.isNotEmpty &&
              userId.trim().isEmpty == false &&
              isMounted.value) {
            switch (next.action) {
              case PostActionType.create:
                FeedPostsPolling.checkForNewPostsWithRetry(
                  ref: ref,
                  userId: userId,
                  posts: posts,
                  newestPostTimestamp: newestPostTimestamp,
                  oldestPostTimestamp: oldestPostTimestamp,
                  newPostsCount: newPostsCount,
                  isMounted: isMounted.value,
                  maxRetries: 3,
                ).then((_) {
                  ref.read(postActionNotifierProvider.notifier).clearAction();
                });
                break;
              case PostActionType.update:
                FeedPostsPolling.checkForPostUpdates(
                  ref: ref,
                  userId: userId,
                  posts: posts,
                ).then((_) {
                  ref.read(postActionNotifierProvider.notifier).clearAction();
                });
                break;
              case PostActionType.delete:
              case PostActionType.hide:
              case PostActionType.report:
                FeedPostsActions.loadInitialPosts(
                  ref: ref,
                  userId: userId,
                  isLoading: isLoading,
                  posts: posts,
                  hasNextPage: hasNextPage,
                  errorMessage: errorMessage,
                  newPostsCount: newPostsCount,
                  newestPostTimestamp: newestPostTimestamp,
                  oldestPostTimestamp: oldestPostTimestamp,
                ).then((_) {
                  ref.read(postActionNotifierProvider.notifier).clearAction();
                });
                break;
            }
          }
        })
        ..listen(postPublishedNotifierProvider, (previous, next) {
          if (next != null &&
              userId.isNotEmpty &&
              userId.trim().isEmpty == false &&
              isMounted.value) {
            FeedPostsPolling.checkForNewPostsWithRetry(
              ref: ref,
              userId: userId,
              posts: posts,
              newestPostTimestamp: newestPostTimestamp,
              oldestPostTimestamp: oldestPostTimestamp,
              newPostsCount: newPostsCount,
              isMounted: isMounted.value,
              maxRetries: 3,
            ).then((_) {
              ref
                  .read(postPublishedNotifierProvider.notifier)
                  .clearPublishedFlag();
            });
          }
        });

      final shouldReload =
          userId != lastUserId.value ||
          effectiveTargetDate != lastTargetDate.value ||
          !hasInitialized.value;

      if (userId.isNotEmpty && userId.trim().isNotEmpty) {
        savedUserId.value = userId;
      }

      if (shouldReload && userId.isNotEmpty && userId.trim().isEmpty == false) {
        lastUserId.value = userId;
        lastTargetDate.value = effectiveTargetDate;
        hasInitialized.value = true;

        FeedPostsActions.loadInitialPosts(
          ref: ref,
          userId: userId,
          isLoading: isLoading,
          posts: posts,
          hasNextPage: hasNextPage,
          errorMessage: errorMessage,
          newPostsCount: newPostsCount,
          newestPostTimestamp: newestPostTimestamp,
          oldestPostTimestamp: oldestPostTimestamp,
        ).then((_) {
          pollingController.startPolling();
          updatePollingController.startPolling();
        });
      } else if ((hasPublishedPost || postActionEvent != null) &&
          userId.isNotEmpty &&
          userId.trim().isEmpty == false) {
        if (postActionEvent != null) {
          switch (postActionEvent.action) {
            case PostActionType.create:
              FeedPostsPolling.checkForNewPostsWithRetry(
                ref: ref,
                userId: userId,
                posts: posts,
                newestPostTimestamp: newestPostTimestamp,
                oldestPostTimestamp: oldestPostTimestamp,
                newPostsCount: newPostsCount,
                isMounted: isMounted.value,
                maxRetries: 3,
              ).then((_) {
                ref.read(postActionNotifierProvider.notifier).clearAction();

                if (!pollingController.isPollingActive) {
                  pollingController.startPolling();
                  updatePollingController.startPolling();
                }
              });
              break;
            case PostActionType.update:
              FeedPostsPolling.checkForPostUpdates(
                ref: ref,
                userId: userId,
                posts: posts,
              ).then((_) {
                ref.read(postActionNotifierProvider.notifier).clearAction();

                if (!pollingController.isPollingActive) {
                  pollingController.startPolling();
                  updatePollingController.startPolling();
                }
              });
              break;
            case PostActionType.delete:
            case PostActionType.hide:
            case PostActionType.report:
              FeedPostsActions.loadInitialPosts(
                ref: ref,
                userId: userId,
                isLoading: isLoading,
                posts: posts,
                hasNextPage: hasNextPage,
                errorMessage: errorMessage,
                newPostsCount: newPostsCount,
                newestPostTimestamp: newestPostTimestamp,
                oldestPostTimestamp: oldestPostTimestamp,
              ).then((_) {
                ref.read(postActionNotifierProvider.notifier).clearAction();

                if (!pollingController.isPollingActive) {
                  pollingController.startPolling();
                  updatePollingController.startPolling();
                }
              });
              break;
          }
        } else {
          FeedPostsPolling.checkForNewPostsWithRetry(
            ref: ref,
            userId: userId,
            posts: posts,
            newestPostTimestamp: newestPostTimestamp,
            oldestPostTimestamp: oldestPostTimestamp,
            newPostsCount: newPostsCount,
            isMounted: isMounted.value,
            maxRetries: 3,
          ).then((_) {
            ref
                .read(postPublishedNotifierProvider.notifier)
                .clearPublishedFlag();

            if (!pollingController.isPollingActive) {
              pollingController.startPolling();
              updatePollingController.startPolling();
            }
          });
        }
      } else if (userId.isEmpty || userId.trim().isEmpty) {
        posts.value = [];
        errorMessage.value = null;
        hasNextPage.value = true;
        newestPostTimestamp.value = null;
        oldestPostTimestamp.value = null;
        newPostsCount.value = 0;
        isLoading.value = false;
        isLoadingMore.value = false;

        hasInitialized.value = false;
        lastUserId.value = null;
        lastTargetDate.value = null;
        pollingController.stopPolling();
        updatePollingController.stopPolling();
      } else {
        // Ensure polling is active even when no action is needed
        if (!pollingController.isPollingActive && hasInitialized.value) {
          pollingController.startPolling();
          updatePollingController.startPolling();
        }
      }

      return () {
        isMounted.value = false;
        // DON'T stop polling here - it's managed by the separate polling useEffect
      };
    },
    [
      userId,
      effectiveTargetDate.millisecondsSinceEpoch,
      postPublishedFlag?.millisecondsSinceEpoch,
      postActionEvent?.timestamp.millisecondsSinceEpoch,
    ],
  );

  void loadMore() {
    if (!isLoadingMore.value &&
        !isLoading.value &&
        hasNextPage.value &&
        userId.isNotEmpty &&
        userId.trim().isNotEmpty) {
      FeedPostsActions.loadOlderPosts(
        ref: ref,
        userId: userId,
        posts: posts,
        isLoadingMore: isLoadingMore,
        hasNextPage: hasNextPage,
        errorMessage: errorMessage,
        oldestPostTimestamp: oldestPostTimestamp,
        effectiveTargetDate: effectiveTargetDate,
        isLoading: isLoading,
      );
    }
  }

  Future<void> refresh() async {
    if (userId.isNotEmpty && userId.trim().isNotEmpty) {
      await FeedPostsActions.loadInitialPosts(
        ref: ref,
        userId: userId,
        isLoading: isLoading,
        posts: posts,
        hasNextPage: hasNextPage,
        errorMessage: errorMessage,
        newPostsCount: newPostsCount,
        newestPostTimestamp: newestPostTimestamp,
        oldestPostTimestamp: oldestPostTimestamp,
      );
    }
  }

  return (
    posts: posts.value,
    isLoading: isLoading.value,
    isLoadingMore: isLoadingMore.value,
    hasNextPage: hasNextPage.value,
    newPostsCount: newPostsCount.value,
    errorMessage: errorMessage.value,

    loadMore: loadMore,
    refresh: refresh,
    loadNewPosts: loadNewPosts,
  );
}
