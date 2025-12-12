import 'package:cloudless/presentation/pages/your_circle/components/your_circle_invite_button.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_join_button.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class YourCircleActionsWidget extends StatelessWidget
    with MainLayout, YourCircleLayout {
  const YourCircleActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: actionsContainerVerticalPadding,
        horizontal: actionsContainerHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: actionsContainerOpacity,
        ),
        borderRadius: BorderRadius.circular(actionsContainerBorderRadius),
      ),
      child: Column(
        children: [
          Text(
            translator.translate('pages.your_circle.box.title'),
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: actionsTitleToDescription),
          Text(
            translator.translate('pages.your_circle.box.description'),
            style: textTheme.bodyMedium?.copyWith(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: actionsDescriptionToButtons),
          Column(
            children: [
              const YourCircleInviteButton(),
              SizedBox(height: actionsBetweenButtons),
              const YourCircleJoinButton(),
            ],
          ),
        ],
      ),
    );
  }
}
