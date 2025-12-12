import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class HomeScrollIndicator extends StatelessWidget with MainLayout, HomeLayout {
  const HomeScrollIndicator({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scrollIndicatorSize,
        height: scrollIndicatorSize,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Center(child: Assets.svg.arrowDown.render()),
      ),
    );
  }
}
