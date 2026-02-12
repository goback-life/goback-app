import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/is_user_connected_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image_layout.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/text/linkable_text.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/home/components/home_lockout_join_button.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final aspectRatio = post.thumbnailWidth / post.thumbnailHeight;
    final isVideo = post.contentType == ContentType.video;
    final isText = post.contentType == ContentType.text;

    final displayImageUrl = post.imageUrl ?? '';

    final textTheme = theme.textTheme;
    final isTextExpanded = useState(false);

    return Padding(
      padding: EdgeInsets.only(top: feedPostTopPadding),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(
                  left: isCurrentUser ? 0 : feedPostOtherUserMarginLeft,
                  right: isCurrentUser ? feedPostCurrentUserMarginRight : 0,
                ),
                width: feedPostWidth,
                child: GestureDetector(
                  onTap: () {
                    if (isText &&
                        !isTextExpanded.value &&
                        _isTextLong(post.description ?? '', textTheme)) {
                      isTextExpanded.value = true;
                    } else {
                      onTap?.call();
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      isText
                          ? _buildTextPost(
                              context, theme, colorScheme, textTheme,
                              isTextExpanded.value)
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
        ],
      ),
    );
  }

  double _calculateTextPostHeight(String text, TextTheme textTheme) {
    final textStyle = textTheme.bodyMedium?.copyWith(color: MainColors.dark) ??
        const TextStyle(color: MainColors.dark);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 5,
    );
    textPainter.layout(maxWidth: feedPostWidth - 32.0);
    return (textPainter.size.height + 32.0).clamp(100.0, 400.0);
  }

  bool _isTextLong(String text, TextTheme textTheme) {
    final textStyle = textTheme.bodyMedium?.copyWith(color: MainColors.dark) ??
        const TextStyle(color: MainColors.dark);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 5,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: feedPostWidth - 32.0);
    return textPainter.didExceedMaxLines;
  }

  Widget _buildTextPost(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isExpanded,
  ) {
    final text = post.description ?? '';
    final textStyle = textTheme.bodyMedium?.copyWith(color: MainColors.dark) ??
        const TextStyle(color: MainColors.dark);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: feedPostWidth,
        child: AppGlassContainer(
          config: GlassConfig(
            variant: GlassVariant.regular,
            cornerRadius: feedPostImageRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LinkableText(
              text: text,
              style: textStyle,
              maxLines: isExpanded ? null : 5,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
            ),
          ),
        ),
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
}
