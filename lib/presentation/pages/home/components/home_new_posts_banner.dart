import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class HomeNewPostsBanner extends StatelessWidget with MainLayout, HomeLayout {
  const HomeNewPostsBanner({
    required this.newPostsCount,
    required this.onTap,
    super.key,
  });

  final int newPostsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (newPostsCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: newPostsBannerSize,
        height: newPostsBannerSize,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$newPostsCount',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.surface,
              fontWeight: FontWeight.w600,
              height: 22.0 / 8.0,
            ),
          ),
        ),
      ),
    );
  }
}
