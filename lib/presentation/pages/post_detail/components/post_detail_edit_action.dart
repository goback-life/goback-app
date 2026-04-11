import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/post_creation_notifier_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_routable.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

/// Menu action for editing a post.
class PostDetailEditAction extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailEditAction({
    required this.post,
    required this.onActionCompleted,
    super.key,
  });

  final FeedPostModel post;
  final VoidCallback onActionCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: () => _handleEdit(context, ref),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: menuItemHorizontalPadding,
          vertical: menuItemVerticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: menuIconSize,
              height: menuIconSize,
              child: Assets.svg.editPost.render(
                colorFilter: theme.colorScheme.onSurface.asSrcIn,
              ),
            ),
            SizedBox(width: menuIconSpacing),
            Text(
              translator.translate('components.post_actions_menu.edit'),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref) {
    ref
        .read(postCreationNotifierProvider.notifier)
        .loadExistingPost(
          postId: post.id,
          description: post.description ?? '',
          taggedUserIds: post.taggedUserIds,
          excludedUserIds: post.excludedUserIds,
          createdAt: post.createdAt,
          contentType: post.contentType,
          imageUrl: post.imageUrl,
          videoUrl: post.videoUrl,
          thumbnailUrl: post.contentType == ContentType.video
              ? post.imageUrl
              : null,
        );

    onActionCompleted();

    router
      ..pop()
      ..push(const ContentEditorRoutable());
  }
}
