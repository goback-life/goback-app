import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image_layout.dart';
import 'package:cloudless/presentation/components/text/linkable_text.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class HomeFeedPostCard extends StatelessWidget
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final aspectRatio = post.thumbnailWidth / post.thumbnailHeight;
    final isVideo = post.contentType == ContentType.video;
    final isText = post.contentType == ContentType.text;

    final displayImageUrl = post.imageUrl ?? '';

    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(top: feedPostTopPadding),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: isCurrentUser ? 0 : feedPostOtherUserMarginLeft,
              right: isCurrentUser ? feedPostCurrentUserMarginRight : 0,
            ),
            width: feedPostWidth,
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: isText
                      ? _buildTextPost(context, theme, colorScheme, textTheme)
                      : AspectRatio(
                          aspectRatio: aspectRatio,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(feedPostImageRadius),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: displayImageUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration:
                                      const Duration(milliseconds: 200),
                                  fadeOutDuration:
                                      const Duration(milliseconds: 100),
                                  memCacheWidth: (feedPostWidth * 2).toInt(),
                                  memCacheHeight:
                                      ((feedPostWidth * 2) / aspectRatio).toInt(),
                                  placeholder: (context, url) => Stack(
                                    children: [
                                      Container(color: colorScheme.surface),
                                      Positioned(
                                        top: placeholderPadding,
                                        left: placeholderPadding,
                                        child: isVideo
                                            ? Assets.svg.placeholderVideo.render()
                                            : Assets.svg.placeholderImage
                                                .render(),
                                      ),
                                    ],
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(color: colorScheme.surface),
                                ),
                                if (isVideo)
                                  Center(
                                    child: Assets.svg.play.render(
                                      colorFilter:
                                          colorScheme.primary.asSrcIn,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '@${post.authorUsername ?? 'Unknown'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPost(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Use thumbnail dimensions for container, with minimum height
    final minHeight = 400.0;
    final containerHeight = (post.thumbnailHeight < minHeight)
        ? minHeight
        : post.thumbnailHeight.toDouble();

    return Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: double.infinity,
      ),
      width: feedPostWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(feedPostImageRadius),
      ),
      padding: const EdgeInsets.all(16.0),
      child: LinkableText(
        text: post.description ?? '',
        style: textTheme.bodyMedium?.copyWith(
          color: Colors.black,
        ),
      ),
    );
  }
}
