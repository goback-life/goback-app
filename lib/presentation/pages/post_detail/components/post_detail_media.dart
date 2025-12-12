import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/full_screen_image.dart';
import 'package:cloudless/presentation/components/video_player/video_player_dialog.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class PostDetailMedia extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailMedia({required this.post, super.key});

  final FeedPostModel post;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final calculatedHeight = (screenHeight * imageHeightRatio).clamp(
      imageMinHeight,
      imageMaxHeight,
    );

    final isVideo = post.contentType == ContentType.video;
    final thumbnailUrl = post.imageUrl ?? '';

    return GestureDetector(
      onTap: () {
        if (isVideo && post.videoUrl != null) {
          VideoPlayerDialog.show(context: context, videoUrl: post.videoUrl!);
        } else {
          FullScreenImage.show(
            context: context,
            image: CachedNetworkImageProvider(thumbnailUrl),
          );
        }
      },
      child: SizedBox(
        width: double.infinity,
        height: calculatedHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(imageRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover),
              if (isVideo) Center(child: Assets.svg.play.render()),
            ],
          ),
        ),
      ),
    );
  }
}
