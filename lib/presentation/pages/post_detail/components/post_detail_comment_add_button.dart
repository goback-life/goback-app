import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
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
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.clear,
          cornerRadius: reactionBorderRadius,
          tint: MainColors.accent,
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
