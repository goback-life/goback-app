import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Navigation header for post detail view that allows navigating between posts.
///
/// Displays the current post date and provides navigation to previous/next posts.
class PostNavigationHeader extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostNavigationHeader({
    required this.currentDate,
    super.key,
    this.onPreviousPost,
    this.onNextPost,
    this.showNavigationArrows = true,
    this.enableNavigation = true,
  });

  final DateTime currentDate;
  final VoidCallback? onPreviousPost;
  final VoidCallback? onNextPost;
  final bool showNavigationArrows;
  final bool enableNavigation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final locale = translator.currentLocale.toString();
    final dayFormat = DateFormatter.formatDate(currentDate, locale);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showNavigationArrows)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: enableNavigation ? onPreviousPost : null,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Assets.svg.back.render(
                      height: navigationHeaderIconSize,
                      width: navigationHeaderIconSize,
                      colorFilter: enableNavigation && onPreviousPost != null
                          ? colorScheme.primary.asSrcIn
                          : colorScheme.surface.withValues(alpha: 0.3).asSrcIn,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: 44, height: 44),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayFormat,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (showNavigationArrows)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: enableNavigation ? onNextPost : null,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Assets.svg.next.render(
                      height: navigationHeaderIconSize,
                      width: navigationHeaderIconSize,
                      colorFilter: enableNavigation && onNextPost != null
                          ? colorScheme.primary.asSrcIn
                          : colorScheme.surface.withValues(alpha: 0.3).asSrcIn,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: 44, height: 44),
          ],
        ),
      ],
    );
  }
}
