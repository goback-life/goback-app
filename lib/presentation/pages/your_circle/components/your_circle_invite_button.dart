import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/invite_to_circle_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class YourCircleInviteButton extends StatelessWidget
    with MainLayout, YourCircleLayout {
  const YourCircleInviteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CallToAction.primary.filled(
      action: () {
        _navigateToInvitePage(context);
      },
      label: Text(
        translator.translate('pages.your_circle.box.invite_button'),
        style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
      ),
    );
  }

  void _navigateToInvitePage(BuildContext context) {
    router.push(const InviteToCircleRoutable());
  }
}
