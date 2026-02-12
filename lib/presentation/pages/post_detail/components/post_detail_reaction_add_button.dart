import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class PostDetailReactionAddButton extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReactionAddButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.clear,
          cornerRadius: reactionBorderRadius,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: reactionHorizontalPadding,
            vertical: reactionVerticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.svg.reaction.render(),
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
