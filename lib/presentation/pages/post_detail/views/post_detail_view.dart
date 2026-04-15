import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/get_calendar_posts_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_mention_autocomplete.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_detail.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_actions.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_actions_menu.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_description.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_header.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_media.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_comments.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_participants.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_reactions.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/utilities/post_detail_navigation.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class PostDetailView extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailView({
    required this.postId,
    this.fallbackPost,
    this.isFromCalendar = false,
    this.calendarUserId,
    this.headerDate,
    super.key,
  });

  final String postId;
  final FeedPostModel? fallbackPost;
  final bool isFromCalendar;
  final String? calendarUserId;
  final DateTime? headerDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final postDetailResult = usePostDetail(
      ref: ref,
      postId: postId,
      fallbackPost: fallbackPost,
    );

    final isMenuVisible = useState(false);

    final currentUserAsync = ref.watch(getCurrentUserProvider);
    final isCurrentUserPost = useMemoized(() {
      final post = postDetailResult.post;
      if (post == null) {
        return false;
      }

      return currentUserAsync.whenOrNull(
            data: (userResult) => userResult.fold(
              (user) => user.id == post.authorId,
              (error) => false,
            ),
          ) ??
          false;
    }, [currentUserAsync, postDetailResult.post?.authorId]);

    useEffect(() {
      var isMounted = true;

      void loadCache() async {
        currentUserAsync.whenData((userResult) async {
          await userResult.fold(
            (user) async {
              if (!isMounted) {
                return;
              }

              final cacheUserId = ref
                  .read(calendarPostsCacheProvider.notifier)
                  .currentUserId;

              if (cacheUserId != user.id ||
                  (isCurrentUserPost && isFromCalendar)) {
                // Reload calendar cache for current user
                // Repository extracts .year/.month from referenceDate.
                final now = DateTime.now();
                final result = await ref.read(
                  getCalendarPostsProvider(
                    userId: user.id,
                    referenceDate: now,
                    direction: CalendarLoadDirection.before,
                    limit: 42,
                  ).future,
                );

                if (!isMounted) return;

                result.fold(
                  (posts) {
                    ref
                        .read(calendarPostsCacheProvider.notifier)
                        .updateCache(posts, userId: user.id);
                  },
                  (error) {
                    ref.read(calendarPostsCacheProvider.notifier).clearCache();
                  },
                );
              }
            },
            (error) async {
              // User fetch failed, nothing to do
            },
          );
        });
      }

      loadCache();

      return () {
        isMounted = false;
      };
    }, [currentUserAsync, postId, isCurrentUserPost]);

    final isPostInCalendar = useMemoized(
      () {
        final posts = ref.watch(calendarPostsCacheProvider);

        if (isCurrentUserPost) {
          return posts.any((p) => p.postId == postId);
        }

        final currentHeaderDate = headerDate;
        if (currentHeaderDate == null) {
          return posts.any((p) => p.postId == postId);
        }

        final normalizedHeaderDate = DateTime(
          currentHeaderDate.year,
          currentHeaderDate.month,
          currentHeaderDate.day,
        );

        return posts.any((p) {
          final postPublishedDate = DateTime(
            p.publishedAt.year,
            p.publishedAt.month,
            p.publishedAt.day,
          );
          return p.postId == postId &&
              postPublishedDate.isAtSameMomentAs(normalizedHeaderDate);
        });
      },
      [
        postId,
        headerDate,
        isCurrentUserPost,
        ref.watch(calendarPostsCacheProvider),
      ],
    );

    final isViewingOtherUserCalendar = useMemoized(() {
      if (!isFromCalendar || calendarUserId == null) {
        return false;
      }

      return currentUserAsync.whenOrNull(
            data: (userResult) => userResult.fold(
              (user) => user.id != calendarUserId,
              (error) => false,
            ),
          ) ??
          false;
    }, [isFromCalendar, calendarUserId, currentUserAsync]);

    final canShowMenu = useMemoized(
      () {
        if (!isFromCalendar) {
          return true;
        }

        DateTime? calendarDate;

        if (headerDate != null) {
          calendarDate = headerDate;
        } else {
          if (!isPostInCalendar) {
            return false;
          }

          final cacheNotifier = ref.read(calendarPostsCacheProvider.notifier);
          calendarDate = cacheNotifier.getPostCalendarDate(postId);
        }

        if (calendarDate == null) {
          return false;
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final postDate = DateTime(
          calendarDate.year,
          calendarDate.month,
          calendarDate.day,
        );

        final isToday = postDate.isAtSameMomentAs(today);

        // Own past calendar posts can't be menu-actioned
        return isToday || !isCurrentUserPost;
      },
      [
        postId,
        isViewingOtherUserCalendar,
        isFromCalendar,
        isPostInCalendar,
        isCurrentUserPost,
        headerDate,
        ref.watch(calendarPostsCacheProvider),
      ],
    );

    final canShowCalendarIcon = useMemoized(() {
      if (!isCurrentUserPost) {
        return false;
      }

      final post = postDetailResult.post;
      if (post == null) {
        return false;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final postCreatedDate = DateTime(
        post.createdAt.year,
        post.createdAt.month,
        post.createdAt.day,
      );

      final isToday = postCreatedDate.isAtSameMomentAs(today);

      return isToday || isPostInCalendar;
    }, [isCurrentUserPost, postDetailResult.post?.createdAt, isPostInCalendar]);

    if (postDetailResult.post == null) {
      return Container(
        padding: EdgeInsets.all(viewPadding),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(viewBorderRadius),
        ),
        child: Center(
          child: Text(
            postDetailResult.errorMessage ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      );
    }

    final post = postDetailResult.post!;

    final mentionState = useMentionAutocomplete(ref);
    final allUsers = mentionState.allUsers;
    final myFriendIds = useMemoized(() => allUsers.map((u) => u.id).toSet(), [
      allUsers,
    ]);

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(viewPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(viewBorderRadius),
          ),
          child: Column(
            children: [
              PostDetailHeader(
                post: post,
                onUserTap: () => PostDetailNavigation.navigateToUserProfile(
                  ref,
                  post.authorId,
                  post.authorUsername ?? 'Unknown',
                ),
              ),
              SizedBox(height: sectionSpacing),
              Expanded(
                child: BottomedListView(
                  useSafeArea: false,
                  bottom: Row(
                    children: [
                      const Spacer(),
                      PostDetailActions(
                        isCurrentUserPost: isCurrentUserPost,
                        isPostInCalendar: isPostInCalendar,
                        showMenu: canShowMenu,
                        showCalendarIcon: canShowCalendarIcon,
                        onMenuTap: () => _handleShowMenu(isMenuVisible),
                      ),
                    ],
                  ),
                  children: [
                    // Goback score for lockout posts
                    if (post.isLockoutPost && post.lockoutScore != null) ...[
                      Text(
                        '${post.lockoutScore}'
                        '${post.lockoutDurationFormatted != null ? ' | ${post.lockoutDurationFormatted}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                    // Only show media for non-text posts
                    if (post.contentType != ContentType.text) ...[
                      PostDetailMedia(post: post),
                      SizedBox(height: sectionSpacing),
                    ],
                    if (post.description?.isNotEmpty == true) ...[
                      PostDetailDescription(
                        description: post.description!,
                        contentType: post.contentType,
                        taggedUsernames: post.taggedUsernames
                            .map((n) => n.toLowerCase())
                            .toSet(),
                        onMentionTap: (username) {
                          final user = allUsers
                              .where((u) => u.username == username)
                              .firstOrNull;
                          if (user != null) {
                            PostDetailNavigation.navigateToUserProfile(
                              ref,
                              user.id,
                              user.username,
                            );
                          }
                        },
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                    Row(
                      children: [
                        PostDetailReactions(
                          post: post,
                          isCurrentUserPost: isCurrentUserPost,
                          isFromCalendar: isFromCalendar,
                        ),
                        SizedBox(width: sectionSpacing),
                        PostDetailComments(
                          post: post,
                          isCurrentUserPost: isCurrentUserPost,
                        ),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                    if (post.isLockoutPost &&
                        post.lockoutParticipantIds.isNotEmpty) ...[
                      PostDetailParticipants(
                        participantIds: post.lockoutParticipantIds,
                        participantUsernames: post.lockoutParticipantUsernames,
                        participantAvatars: post.lockoutParticipantAvatars,
                        participantJoinedVia: post.lockoutParticipantJoinedVia,
                        myFriendIds: myFriendIds,
                        onFriendTap: (userId, username) =>
                            PostDetailNavigation.navigateToUserProfile(
                              ref,
                              userId,
                              username,
                            ),
                        onFriendOfFriendTap: (userId, username, _) =>
                            PostDetailNavigation.navigateToUserProfile(
                              ref,
                              userId,
                              username,
                            ),
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isMenuVisible.value)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => isMenuVisible.value = false,
              child: Container(color: Colors.transparent),
            ),
          ),
        if (isMenuVisible.value)
          Positioned(
            bottom: sheetBottomMenuPosition,
            right: sheetHorizontalPosition,
            child: Material(
              color: Colors.transparent,
              child: PostDetailActionsMenu(
                post: post,
                isCurrentUserPost: isCurrentUserPost,
                isAuthorConnected: post.isAuthorConnected,
                showHideOption: !isFromCalendar,
                onActionCompleted: () => isMenuVisible.value = false,
              ),
            ),
          ),
      ],
    );
  }

  void _handleShowMenu(ValueNotifier<bool> isMenuVisible) {
    isMenuVisible.value = !isMenuVisible.value;
  }
}
