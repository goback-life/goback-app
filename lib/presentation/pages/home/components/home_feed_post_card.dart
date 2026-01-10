import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_creation_initialization.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/models/parent_post_reference_model.dart';
import 'package:cloudless/core/features/post/domain/providers/parent_post_reference_notifier_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image_layout.dart';
import 'package:cloudless/presentation/components/text/linkable_text.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/home/components/home_lockout_join_button.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeFeedPostCard extends HookConsumerWidget
    with MainLayout, HomeLayout, ProfileImageLayout {
  const HomeFeedPostCard({
    required this.post,
    required this.isCurrentUser,
    this.onTap,
    super.key,
  });

  final FeedPostModel post;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  
  // Threshold for triggering reply (percentage of post width)
  static const double _swipeThreshold = 0.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final aspectRatio = post.thumbnailWidth / post.thumbnailHeight;
    final isVideo = post.contentType == ContentType.video;
    final isText = post.contentType == ContentType.text;
    final isReply = post.parentId != null;

    final displayImageUrl = post.imageUrl ?? '';

    final textTheme = theme.textTheme;

    // Initialize post creation for reply if this is another user's connected post
    final canReply = !isCurrentUser && post.isAuthorConnected;
    final parentPostReference = canReply
        ? ParentPostReferenceModel(
            id: post.id,
            authorId: post.authorId,
            authorUsername: post.authorUsername ?? 'Unknown',
            thumbnailUrl: post.imageUrl ?? '',
            thumbnailWidth: post.thumbnailWidth,
            thumbnailHeight: post.thumbnailHeight,
            contentType: post.contentType,
          )
        : null;

    // Always call hook (hooks must be called unconditionally)
    final postCreationInitialization = usePostCreationInitialization(
      ref,
      parentPost: parentPostReference,
      onNavigateToEditor: () {
        if (context.mounted) {
          router.pop();
        }
      },
    );

    // Animation for swipe gesture
    final dragOffset = useState<double>(0.0);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final bounceAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    // Offset amount for reply posts
    const replyOffset = 24.0;
    // Arrow icon size
    const arrowIconSize = 20.0;
    // Spacing between arrow and post
    const arrowSpacing = 8.0;

    return Padding(
      padding: EdgeInsets.only(top: feedPostTopPadding),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Reply arrow (left side for other users)
          if (isReply && !isCurrentUser) ...[
            GestureDetector(
              onTap: () => _navigateToParentPost(context, ref),
              child: Container(
                width: arrowIconSize,
                height: arrowIconSize,
                margin: EdgeInsets.only(
                  right: arrowSpacing,
                ),
                child: Assets.svg.answer.render(
                  colorFilter: colorScheme.primary.asSrcIn,
                ),
              ),
            ),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(
                  left: isCurrentUser
                      ? (isReply ? replyOffset : 0)
                      : (isReply ? replyOffset : feedPostOtherUserMarginLeft),
                  right: isCurrentUser
                      ? (isReply ? replyOffset : feedPostCurrentUserMarginRight)
                      : (isReply ? replyOffset : 0),
                ),
                width: feedPostWidth,
                child: GestureDetector(
                  onTap: onTap,
                  onHorizontalDragUpdate: canReply
                      ? (details) => _handleSwipeUpdate(
                            details,
                            dragOffset,
                            feedPostWidth,
                          )
                      : null,
                  onHorizontalDragEnd: canReply
                      ? (details) => _handleSwipeEnd(
                            context,
                            ref,
                            details,
                            dragOffset,
                            animationController,
                            feedPostWidth,
                            postCreationInitialization,
                          )
                      : null,
                  behavior: HitTestBehavior.translucent,
                  child: AnimatedBuilder(
                    animation: bounceAnimation,
                    builder: (context, child) {
                      final offset = canReply
                          ? dragOffset.value * (1 - bounceAnimation.value)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: isCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        isText
                            ? _buildTextPost(
                                context, theme, colorScheme, textTheme)
                            : AspectRatio(
                                aspectRatio: aspectRatio,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      feedPostImageRadius),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: displayImageUrl,
                                        fit: BoxFit.cover,
                                        fadeInDuration: const Duration(
                                            milliseconds: 200),
                                        fadeOutDuration: const Duration(
                                            milliseconds: 100),
                                        memCacheWidth:
                                            (feedPostWidth * 2).toInt(),
                                        memCacheHeight: ((feedPostWidth * 2) /
                                                aspectRatio)
                                            .toInt(),
                                        placeholder: (context, url) => Stack(
                                          children: [
                                            Container(
                                                color: colorScheme.surface),
                                            Positioned(
                                              top: placeholderPadding,
                                              left: placeholderPadding,
                                              child: isVideo
                                                  ? Assets.svg
                                                      .placeholderVideo
                                                      .render()
                                                  : Assets.svg
                                                      .placeholderImage
                                                      .render(),
                                            ),
                                          ],
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                                color: colorScheme.surface),
                                      ),
                                      if (isVideo)
                                        Center(
                                          child: Assets.svg.play.render(
                                            colorFilter: colorScheme.primary
                                                .asSrcIn,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () => _navigateToUserProfile(ref),
                          child: Text(
                            '@${post.authorUsername ?? 'Unknown'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Show join button on the right side (closest to middle) for other users' lockout posts
              // Uses database flag for security - only posts created through official lockout flow
              if (!isCurrentUser && post.isLockoutPost)
                Builder(
                  builder: (context) {
                    // Calculate post preview height
                    final postHeight = isText
                        ? _calculateTextPostHeight(
                            post.description ?? '', textTheme)
                        : feedPostWidth / aspectRatio;
                    return HomeLockoutJoinButton(
                      post: post,
                      postHeight: postHeight,
                    );
                  },
                ),
            ],
          ),
          // Reply arrow (right side for current user)
          if (isReply && isCurrentUser) ...[
            GestureDetector(
              onTap: () => _navigateToParentPost(context, ref),
              child: Container(
                width: arrowIconSize,
                height: arrowIconSize,
                margin: EdgeInsets.only(
                  left: arrowSpacing,
                ),
                child: Assets.svg.answer.render(
                  colorFilter: colorScheme.primary.asSrcIn,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateTextPostHeight(String text, TextTheme textTheme) {
    // For preview, use up to 200 characters
    final previewText = text.length > 200 ? '${text.substring(0, 200)}...' : text;
    
    // Calculate height based on actual text layout
    // Use TextPainter to get accurate height measurement
    final textStyle = textTheme.bodyMedium?.copyWith(color: Colors.black) ??
        const TextStyle(color: Colors.black);
    final textPainter = TextPainter(
      text: TextSpan(text: previewText, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    
    // Layout with available width (feedPostWidth - padding)
    final availableWidth = feedPostWidth - 32.0; // 16px padding on each side
    textPainter.layout(maxWidth: availableWidth);
    
    // Calculate height: text height + padding (16px top + 16px bottom)
    final minHeight = 100.0;
    final maxHeight = 400.0;
    return (textPainter.size.height + 32.0).clamp(minHeight, maxHeight);
  }

  Widget _buildTextPost(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final text = post.description ?? '';
    
    // For preview, use up to 200 characters
    final previewText = text.length > 200 ? '${text.substring(0, 200)}...' : text;
    
    // Calculate height
    final calculatedHeight = _calculateTextPostHeight(text, textTheme);
    
    final textStyle = textTheme.bodyMedium?.copyWith(color: Colors.black) ??
        const TextStyle(color: Colors.black);
    final minHeight = 100.0;
    final maxHeight = 400.0;

    return Container(
      width: feedPostWidth,
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
      ),
      height: calculatedHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(feedPostImageRadius),
      ),
      padding: const EdgeInsets.all(16.0),
      child: LinkableText(
        text: previewText,
        style: textStyle,
        maxLines: null,
      ),
    );
  }

  Future<void> _navigateToUserProfile(WidgetRef ref) async {
    final currentUserAsync = ref.read(getCurrentUserProvider);
    final isCurrentUser = currentUserAsync.whenOrNull(
          data: (userResult) =>
              userResult.fold((user) => user.id == post.authorId, (error) => false),
        ) ??
        false;

    if (isCurrentUser) {
      router.push(const ProfileRoutable());
    } else {
      final connectionResult = await ref.read(
        isUserConnectedProvider(post.authorId).future,
      );
      final isConnected = connectionResult.fold((isConnected) => isConnected, (
        error,
      ) {
        logger.error('Failed to check user connection', exception: error);
        return false;
      });

      if (isConnected) {
        router.push(CircleProfileRoutable(userId: post.authorId));
      } else {
        router.push(ExternalProfileRoutable(userId: post.authorId));
      }
    }
  }

  Future<void> _navigateToParentPost(BuildContext context, WidgetRef ref) async {
    if (post.parentId == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) => GestureDetector(
        onTap: () => Navigator.of(sheetContext).pop(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                top: 150.0,
                bottom: 20.0,
              ),
              child: PostDetailPage.byId(
                postId: post.parentId!,
                isFromCalendar: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSwipeUpdate(
    DragUpdateDetails details,
    ValueNotifier<double> dragOffset,
    double postWidth,
  ) {
    // Only allow swiping right (positive delta)
    if (details.primaryDelta != null && details.primaryDelta! > 0) {
      final newOffset = (dragOffset.value + details.primaryDelta!).clamp(
        0.0,
        postWidth * 0.5, // Limit max drag to half the post width
      );
      dragOffset.value = newOffset;
    }
  }

  void _handleSwipeEnd(
    BuildContext context,
    WidgetRef ref,
    DragEndDetails details,
    ValueNotifier<double> dragOffset,
    AnimationController animationController,
    double postWidth,
    PostCreationInitializationResult postCreationInitialization,
  ) {
    final threshold = postWidth * _swipeThreshold;
    final shouldTriggerReply = dragOffset.value >= threshold;

    if (shouldTriggerReply) {
      // Trigger reply
      _handleReply(context, ref, postCreationInitialization);
      // Reset offset after a brief delay
      Future.delayed(const Duration(milliseconds: 100), () {
        dragOffset.value = 0.0;
      });
    } else {
      // Bounce back
      animationController.forward(from: 0.0).then((_) {
        dragOffset.value = 0.0;
        animationController.reset();
      });
    }
  }

  Future<void> _handleReply(
    BuildContext context,
    WidgetRef ref,
    PostCreationInitializationResult postCreationInitialization,
  ) async {
    final parentPostReference = ParentPostReferenceModel(
      id: post.id,
      authorId: post.authorId,
      authorUsername: post.authorUsername ?? 'Unknown',
      thumbnailUrl: post.imageUrl ?? '',
      thumbnailWidth: post.thumbnailWidth,
      thumbnailHeight: post.thumbnailHeight,
      contentType: post.contentType,
    );

    await ref
        .read(parentPostReferenceNotifierProvider.notifier)
        .setParentPost(parentPostReference);

    ref
        .read(postCreationNotifierProvider.notifier)
        .loadReplyMode(parentId: post.id);

    postCreationInitialization.selectMainImage();
  }
}
