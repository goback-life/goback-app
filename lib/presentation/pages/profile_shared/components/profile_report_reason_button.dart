import 'package:cloudless/core/features/profile/domain/enums/user_report_reason.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/profile_shared/profile_actions_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class ProfileReportReasonButton extends StatelessWidget
    with MainLayout, ProfileActionsLayout {
  const ProfileReportReasonButton({
    required this.reason,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    super.key,
  });

  final UserReportReason reason;
  final String label;
  final void Function(UserReportReason reason) onPressed;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (isSecondary) {
      return CallToAction.primary.outlined(
        action: () => onPressed(reason),
        label: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            height: 20.0 / 14.0,
            color: colorScheme.surfaceContainerLow,
          ),
        ),
        horizontalMargin: modalHorizontalMargin,
        height: modalButtonHeight,
      );
    }

    return CallToAction.danger.outlined(
      action: () => onPressed(reason),
      label: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          height: 20.0 / 14.0,
          color: colorScheme.error,
        ),
      ),
      horizontalMargin: modalHorizontalMargin,
      height: modalButtonHeight,
    );
  }
}
