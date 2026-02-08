import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class PostDetailCommentAddButton extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailCommentAddButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(reactionBorderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: reactionHorizontalPadding,
            vertical: reactionVerticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: commentIconSize,
                color: colorScheme.onSurface,
              ),
              SizedBox(width: reactionIconSpacing),
              Assets.svg.plus.render(
                width: reactionIconSize,
                height: reactionIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
