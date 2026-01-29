import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeFeedEmptyState extends HookConsumerWidget
    with MainLayout, HomeLayout {
  const HomeFeedEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      height: 180,
      padding: EdgeInsets.symmetric(
        vertical: actionsContainerVerticalPadding,
        horizontal: actionsContainerHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(actionsContainerBorderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            translator.translate(
              'pages.home.feed_empty_box.no_activity_title',
            ),
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: actionsTitleToDescription),
          Text(
            translator.translate(
              'pages.home.feed_empty_box.no_activity_description',
            ),
            style: textTheme.bodyMedium?.copyWith(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
