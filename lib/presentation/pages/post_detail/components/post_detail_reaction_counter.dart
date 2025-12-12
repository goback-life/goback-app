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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
