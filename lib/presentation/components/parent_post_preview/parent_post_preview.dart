import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/parent_post_reference_model.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/parent_post_preview/parent_post_preview_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Widget that shows a compact view of the parent post
/// during reply creation to keep the user's context.
/// If the parent post is deleted (during edit flow), the thumbnail is blurred.
class ParentPostPreview extends HookConsumerWidget
    with MainLayout, ParentPostPreviewLayout {
  const ParentPostPreview({required this.parentPost, super.key});

  final ParentPostReferenceModel parentPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isVideo = parentPost.contentType == ContentType.video;
    final isDeleted = parentPost.isDeleted;
    final hasThumbnail = parentPost.thumbnailUrl.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasThumbnail)
          ClipRRect(
            borderRadius: BorderRadius.circular(parentPostPreviewBorderRadius),
            child: SizedBox(
              width: parentPostPreviewThumbnailWidth,
              height: parentPostPreviewThumbnailHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: parentPost.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                  if (isDeleted)
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: parentPostPreviewBlurSigma,
                        sigmaY: parentPostPreviewBlurSigma,
                      ),
                      child: Container(
                        color: colorScheme.secondary.withValues(
                          alpha: parentPostPreviewBlurOpacity,
                        ),
                      ),
                    ),
                  if (isVideo && !isDeleted)
                    Center(
                      child: Assets.svg.play.render(
                        height: parentPostPreviewPlayIconSize,
                        width: parentPostPreviewPlayIconSize,
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (hasThumbnail)
          SizedBox(width: parentPostPreviewThumbnailToUsername),
        Text('@${parentPost.authorUsername}', style: textTheme.titleMedium),
      ],
    );
  }
}
