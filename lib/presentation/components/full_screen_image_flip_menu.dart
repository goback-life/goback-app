import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Menu for flipping image horizontally or vertically in fullscreen view.
class FullScreenImageFlipMenu extends HookConsumerWidget with MainLayout {
  const FullScreenImageFlipMenu({
    required this.onFlipHorizontal,
    required this.onFlipVertical,
    super.key,
  });

  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;

  /// Menu styling constants
  static const double menuVerticalSpacing = 8.0;
  static const double menuBorderRadius = 16.0;
  static const double menuBorderWidth = 2.0;
  static const double menuShadowOpacity = 0.8;
  static const double menuShadowBlur = 20.0;
  static const double menuShadowOffsetY = 2.0;
  static const double menuDividerHeight = 1.0;
  static const double menuItemHorizontalPadding = 16.0;
  static const double menuItemVerticalPadding = 12.0;
  static const double menuIconSize = 20.0;
  static const double menuIconSpacing = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: menuVerticalSpacing),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(menuBorderRadius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: menuShadowOpacity),
            blurRadius: menuShadowBlur,
            spreadRadius: 0,
            offset: const Offset(0, menuShadowOffsetY),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FlipAction(
              icon: Assets.svg.flipHorizontal.render(),
              label: translator.translate(
                'components.full_screen_image_flip_menu.flip_horizontal',
              ),
              onTap: () {
                Navigator.of(context).pop();
                onFlipHorizontal();
              },
              textTheme: textTheme,
            ),
            Container(height: menuDividerHeight, color: colorScheme.shadow),
            _FlipAction(
              icon: Assets.svg.flipVertical.render(),
              label: translator.translate(
                'components.full_screen_image_flip_menu.flip_vertical',
              ),
              onTap: () {
                Navigator.of(context).pop();
                onFlipVertical();
              },
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual action item in the flip menu
class _FlipAction extends StatelessWidget {
  const _FlipAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.textTheme,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FullScreenImageFlipMenu.menuItemHorizontalPadding,
          vertical: FullScreenImageFlipMenu.menuItemVerticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: FullScreenImageFlipMenu.menuIconSize,
              height: FullScreenImageFlipMenu.menuIconSize,
              child: icon,
            ),
            const SizedBox(width: FullScreenImageFlipMenu.menuIconSpacing),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
