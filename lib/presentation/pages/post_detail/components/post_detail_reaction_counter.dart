import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class PostDetailReactionCounter extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailReactionCounter({
    required this.uniqueEmojis,
    required this.totalCount,
    required this.onTap,
    super.key,
  });

  final List<String> uniqueEmojis;
  final int totalCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              ...uniqueEmojis.map(
                (emoji) => Padding(
                  padding: EdgeInsets.only(right: reactionIconSpacing),
                  child: Text(
                    emoji,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Text(
                '$totalCount',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
