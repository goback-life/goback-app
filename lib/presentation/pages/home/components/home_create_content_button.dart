import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class HomeCreateContentButton extends StatelessWidget
    with MainLayout, HomeLayout {
  const HomeCreateContentButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(feedPostImageBorderRadius),
        width: createContentButtonSize,
        height: createContentButtonSize,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Assets.svg.plus.render(),
      ),
    );
  }
}
