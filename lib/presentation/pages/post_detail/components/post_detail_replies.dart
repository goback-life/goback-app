import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/get_post_replies_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_page.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

/// Widget that displays a horizontal scrollable list of replies to a post.
/// Each reply shows a preview (thumbnail or "T" for text) and the username.
class PostDetailReplies extends ConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReplies({
    required this.postId,
    super.key,
  });

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final repliesAsync = ref.watch(getPostRepliesProvider(postId: postId));

    return repliesAsync.when(
      data: (result) {
        return result.fold(
          (replies) {
            if (replies.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: sectionSpacing),
                  child: Text(
                    'Replies',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                ...replies.map((reply) => Padding(
                  padding: EdgeInsets.only(bottom: replyPreviewSpacing),
                  child: _ReplyPreviewItem(
                    reply: reply,
                    onTap: () {
                      PostDetailPage.show(
                        context,
                        post: reply,
                      );
                    },
                  ),
                )),
                SizedBox(height: sectionSpacing),
              ],
            );
          },
          (error) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _ReplyPreviewItem extends ConsumerWidget {
  const _ReplyPreviewItem({
    required this.reply,
    required this.onTap,
  });

  final FeedPostModel reply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isText = reply.contentType == ContentType.text;
    final isVideo = reply.contentType == ContentType.video;

    // Constants from PostDetailLayout
    const replyPreviewWidth = 80.0;
    const replyPreviewHeight = 80.0;
    const replyPreviewBorderRadius = 6.0;
    const replyPreviewSpacing = 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(replyPreviewBorderRadius),
            child: Container(
              width: replyPreviewWidth,
              height: replyPreviewHeight,
              color: isText ? Colors.white : colorScheme.surface,
              child: isText
                  ? Center(
                      child: Text(
                        'T',
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        if (reply.imageUrl != null && reply.imageUrl!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: reply.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surface,
                            ),
                          )
                        else
                          Container(color: colorScheme.surface),
                        if (isVideo)
                          Center(
                            child: Assets.svg.play.render(
                              colorFilter: colorScheme.primary.asSrcIn,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SizedBox(width: replyPreviewSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${reply.authorUsername ?? 'Unknown'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isText && reply.description != null && reply.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reply.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

