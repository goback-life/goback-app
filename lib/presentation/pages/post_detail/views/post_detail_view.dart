import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_detail.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_actions.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_actions_menu.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_description.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_header.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_media.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_parent_preview.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_reactions.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_tags.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/utilities/post_detail_calendar.dart';
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

    final isExcludedFromParent = useMemoized(() {
      final post = postDetailResult.post;
      if (post == null || post.parentId == null) {
        return false;
      }

      return currentUserAsync.whenOrNull(
            data: (userResult) => userResult.fold(
              (user) => post.parentExcludedUserIds.contains(user.id),
              (error) => false,
            ),
          ) ??
          false;
    }, [currentUserAsync, postDetailResult.post?.parentExcludedUserIds]);

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
                await PostDetailCalendar.reloadCalendarCache(
                  ref,
                  user.id,
                  isMounted: () => isMounted,
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
          final postCalendarDate = DateTime(
            p.calendarDate.year,
            p.calendarDate.month,
            p.calendarDate.day,
          );
          return p.postId == postId &&
              postCalendarDate.isAtSameMomentAs(normalizedHeaderDate);
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

        if (!isToday && isCurrentUserPost) {
          return false;
        }

        if (!isToday && !isCurrentUserPost) {
          return true;
        }

        return true;
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

    final canShowCalendarIcon = useMemoized(
      () {
        if (!isCurrentUserPost) {
          return false;
        }

        final post = postDetailResult.post;
        if (post == null) {
          return false;
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final postContentDate = DateTime(
          post.contentDate.year,
          post.contentDate.month,
          post.contentDate.day,
        );

        final isToday = postContentDate.isAtSameMomentAs(today);

        return isToday || isPostInCalendar;
      },
      [isCurrentUserPost, postDetailResult.post?.contentDate, isPostInCalendar],
    );

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
                      if (post.parentId != null &&
                          post.parentThumbnailUrl != null &&
                          !isExcludedFromParent) ...[
                        PostDetailParentPreview(
                          thumbnailUrl: post.parentThumbnailUrl!,
                          isParentVideo:
                              post.parentContentType == ContentType.video,
                          isParentDeleted: post.parentDeletedAt != null,
                          onTap: () =>
                              PostDetailNavigation.navigateToParentPost(
                                context,
                                ref,
                                post.parentId!,
                                post,
                                isFromCalendar: isFromCalendar,
                                headerDate: headerDate,
                                calendarUserId: calendarUserId,
                              ),
                        ),
                      ],
                      const Spacer(),
                      PostDetailActions(
                        isCurrentUserPost: isCurrentUserPost,
                        isPostInCalendar: isPostInCalendar,
                        showMenu: canShowMenu,
                        showCalendarIcon: canShowCalendarIcon,
                        onCalendarTap: () =>
                            PostDetailCalendar.handleCalendarToggle(
                              context,
                              ref,
                              post,
                              isPostInCalendar,
                            ),
                        onMenuTap: () => _handleShowMenu(isMenuVisible),
                      ),
                    ],
                  ),
                  children: [
                    PostDetailMedia(post: post),
                    SizedBox(height: sectionSpacing),
                    PostDetailReactions(
                      post: post,
                      isCurrentUserPost: isCurrentUserPost,
                      isFromCalendar: isFromCalendar,
                    ),
                    SizedBox(height: sectionSpacing),
                    if (post.taggedUsernames.isNotEmpty) ...[
                      PostDetailTags(
                        taggedUsernames: post.taggedUsernames,
                        taggedUserIds: post.taggedUserIds,
                        onUserTap: (userId, username) =>
                            PostDetailNavigation.navigateToUserProfile(
                              ref,
                              userId,
                              username,
                            ),
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                    if (post.description?.isNotEmpty == true) ...[
                      PostDetailDescription(
                        description: post.description!,
                        contentType: post.contentType,
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
