import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

/// Widget that shows a compact preview of the parent post's media
/// in the post detail view when the current post is a reply.
///
/// Displays only the media thumbnail with a parent icon indicator.
/// If the parent post is deleted, the thumbnail is blurred and tapping is disabled.
class PostDetailParentPreview extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailParentPreview({
    required this.thumbnailUrl,
    required this.onTap,
    this.isParentVideo = false,
    this.isParentDeleted = false,
    super.key,
  });

  final String thumbnailUrl;
  final VoidCallback onTap;
  final bool isParentVideo;
  final bool isParentDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVideo = isParentVideo;

    return GestureDetector(
      onTap: isParentDeleted ? null : onTap,
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Assets.svg.parent.render(),
          SizedBox(width: parentPreviewSpacing),
          ClipRRect(
            borderRadius: BorderRadius.circular(parentPreviewBorderRadius),
            child: SizedBox(
              width: parentPreviewThumbnailWidth,
              height: parentPreviewThumbnailHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover),
                  if (isParentDeleted)
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: parentPreviewBlurSigma,
                        sigmaY: parentPreviewBlurSigma,
                      ),
                      child: Container(
                        color: colorScheme.secondary.withValues(
                          alpha: parentPreviewBlurOpacity,
                        ),
                      ),
                    ),
                  if (isVideo && !isParentDeleted)
                    Center(
                      child: Assets.svg.play.render(
                        height: parentPreviewPlayIconSize,
                        width: parentPreviewPlayIconSize,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
