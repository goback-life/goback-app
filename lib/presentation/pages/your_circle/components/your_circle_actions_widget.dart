import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/review_circle/review_circle_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_invite_button.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_join_button.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class YourCircleActionsWidget extends HookConsumerWidget
    with MainLayout, YourCircleLayout {
  const YourCircleActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final circleMembersData = useCircleMembers(ref);
    final friendCount = circleMembersData.allUsers.map((user) => user.id).toSet().length;
    final isAtLimit = friendCount >= 150;

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
          if (isAtLimit)
            Text(
              translator.translate('pages.your_circle.box.remove_friend_message'),
              style: textTheme.bodyMedium?.copyWith(),
              textAlign: TextAlign.center,
            )
          else
            Text(
              translator.translate('pages.your_circle.box.description'),
              style: textTheme.bodyMedium?.copyWith(),
              textAlign: TextAlign.center,
            ),
          if (isAtLimit) ...[
            SizedBox(height: actionsDescriptionToButtons),
            CallToAction.primary.filled(
              action: () {
                router.push(const ReviewCircleRoutable());
              },
              label: Text(
                translator.translate('pages.your_circle.box.review_button'),
                style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
              ),
            ),
          ] else ...[
            SizedBox(height: actionsDescriptionToButtons),
            Column(
              children: [
                const YourCircleInviteButton(),
                SizedBox(height: actionsBetweenButtons),
                const YourCircleJoinButton(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
