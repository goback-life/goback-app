import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/post_detail/post_detail_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class PostDetailActions extends StatelessWidget
    with MainLayout, PostDetailLayout {
  const PostDetailActions({
    required this.isCurrentUserPost,
    required this.isPostInCalendar,
    required this.onCalendarTap,
    required this.onMenuTap,
    this.showMenu = true,
    this.showCalendarIcon = true,
    super.key,
  });

  final bool isCurrentUserPost;
  final bool isPostInCalendar;
  final bool showMenu;
  final bool showCalendarIcon;
  final VoidCallback onCalendarTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isCurrentUserPost && showCalendarIcon)
          GestureDetector(
            onTap: onCalendarTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPostInCalendar
                    ? colorScheme.primaryContainer
                    : colorScheme.primaryContainer.withValues(alpha: 0.1),
              ),
              child: Padding(
                padding: EdgeInsets.all(iconPadding),
                child: Assets.svg.addToCalendar.render(
                  colorFilter: isPostInCalendar
                      ? colorScheme.surface.asSrcIn
                      : colorScheme.primaryContainer.asSrcIn,
                ),
              ),
            ),
          ),
        if (showMenu) ...[
          if (isCurrentUserPost && showCalendarIcon)
            SizedBox(width: actionSpacing),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onMenuTap,
            child: SizedBox(
              height: iconHeight,
              width: iconWidth,
              child: Center(child: Assets.svg.menu.render()),
            ),
          ),
        ],
      ],
    );
  }
}
