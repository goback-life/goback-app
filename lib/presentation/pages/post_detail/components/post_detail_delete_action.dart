import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/delete_post_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Menu action for deleting a post.
class PostDetailDeleteAction extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailDeleteAction({
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
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _handleDelete(context, ref),
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
              child: Assets.svg.deleteIcon.render(
                colorFilter: colorScheme.error.asSrcIn,
              ),
            ),
            SizedBox(width: menuIconSpacing),
            Text(
              translator.translate('components.post_actions_menu.delete'),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    await MainAlert.showFull(
      context: context,
      title: translator.translate('components.delete_post.title'),
      content: Text(
        translator.translate('components.delete_post.content'),
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.outlineVariant,
        ),
        textAlign: TextAlign.center,
      ),
      primaryButtonText: translator.translate('components.delete_post.confirm'),
      secondaryButtonText: translator.translate(
        'components.delete_post.cancel',
      ),
      primaryButtonType: CallToActionType.danger,
      onPrimaryPressed: () async {
        router.pop();

        final currentUserAsync = ref.read(getCurrentUserProvider);
        final authorId = currentUserAsync.whenOrNull(
          data: (userResult) =>
              userResult.fold((user) => user.id, (error) => null),
        );

        if (authorId == null) {
          if (context.mounted) {
            await MainAlert.showError(
              context: context,
              title: translator.translate('components.delete_post.error_title'),
              content: translator.translate(
                'components.delete_post.error_content',
              ),
            );
            onActionCompleted();
          } else {
            onActionCompleted();
          }
          return;
        }

        final result = await ref.read(
          deletePostProvider(postId: post.id, authorId: authorId).future,
        );

        result.fold(
          (_) {
            ref.read(postActionNotifierProvider.notifier).notifyPostDeleted();
            onActionCompleted();

            if (context.mounted) {
              router.pop();
            }
          },
          (error) async {
            logger.error('Failed to delete post', exception: error);

            if (context.mounted) {
              await MainAlert.showError(
                context: context,
                title: translator.translate(
                  'components.delete_post.error_title',
                ),
                content: translator.translate(
                  'components.delete_post.error_content',
                ),
              );
              onActionCompleted();
            } else {
              onActionCompleted();
            }
          },
        );
      },
      onSecondaryPressed: () {
        onActionCompleted();
        router.pop();
      },
    );
  }
}
