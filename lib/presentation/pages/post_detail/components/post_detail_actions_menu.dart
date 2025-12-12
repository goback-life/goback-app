import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_delete_action.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_edit_action.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_hide_action.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_report_action.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class PostDetailActionsMenu extends HookConsumerWidget
    with MainLayout, PostDetailLayout {
  const PostDetailActionsMenu({
    required this.post,
    required this.isCurrentUserPost,
    required this.isAuthorConnected,
    required this.onActionCompleted,
    this.showHideOption = true,
    super.key,
  });

  final FeedPostModel post;
  final bool isCurrentUserPost;
  final bool isAuthorConnected;
  final bool showHideOption;
  final VoidCallback onActionCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(vertical: menuVerticalSpacing),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(menuBorderRadius),
        border: Border.all(color: colorScheme.shadow, width: menuBorderWidth),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: menuShadowOpacity),
            blurRadius: menuShadowBlur,
            spreadRadius: 0,
            offset: Offset(0, menuShadowOffsetY),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isCurrentUserPost) ...[
              PostDetailEditAction(
                post: post,
                onActionCompleted: onActionCompleted,
              ),
              Container(height: menuDividerHeight, color: colorScheme.shadow),
              PostDetailDeleteAction(
                post: post,
                onActionCompleted: onActionCompleted,
              ),
            ] else ...[
              if (isAuthorConnected && showHideOption) ...[
                PostDetailHideAction(
                  post: post,
                  onActionCompleted: onActionCompleted,
                ),
                Container(height: menuDividerHeight, color: colorScheme.shadow),
              ],
              PostDetailReportAction(
                post: post,
                onActionCompleted: onActionCompleted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
