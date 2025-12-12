import 'dart:ui';

import 'package:cloudless/core/features/profile/domain/enums/user_report_reason.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_report_reason_button.dart';
import 'package:cloudless/presentation/pages/profile_shared/profile_actions_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class ProfileReportReasonModal extends StatelessWidget
    with MainLayout, ProfileActionsLayout {
  const ProfileReportReasonModal({required this.onReasonSelected, super.key});

  final void Function(UserReportReason reason) onReasonSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Container(
        color: colorScheme.onSurface.withValues(alpha: 0.1),
        child: Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(modalBorderRadius),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: modalHorizontalPadding,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: modalVerticalPadding,
              horizontal: modalHorizontalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  translator.translate('components.user_report_modal.title'),
                  style: textTheme.titleLarge?.copyWith(height: 26.0 / 20.0),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: modalTitleToDescription),
                Text(
                  translator.translate('components.user_report_modal.subtitle'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outlineVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: modalDescriptionToActions),
                ProfileReportReasonButton(
                  reason: UserReportReason.harassment,
                  label: translator.translate(
                    'components.user_report_modal.reasons.harassment',
                  ),
                  onPressed: onReasonSelected,
                ),
                SizedBox(height: modalActionSpacing),
                ProfileReportReasonButton(
                  reason: UserReportReason.hateSpeech,
                  label: translator.translate(
                    'components.user_report_modal.reasons.hate_speech',
                  ),
                  onPressed: onReasonSelected,
                ),
                SizedBox(height: modalActionSpacing),
                ProfileReportReasonButton(
                  reason: UserReportReason.inappropriateContent,
                  label: translator.translate(
                    'components.user_report_modal.reasons.inappropriate_content',
                  ),
                  onPressed: onReasonSelected,
                ),
                SizedBox(height: modalActionSpacing),
                ProfileReportReasonButton(
                  reason: UserReportReason.spam,
                  label: translator.translate(
                    'components.user_report_modal.reasons.spam',
                  ),
                  onPressed: onReasonSelected,
                ),
                SizedBox(height: modalActionSpacing),
                ProfileReportReasonButton(
                  reason: UserReportReason.impersonation,
                  label: translator.translate(
                    'components.user_report_modal.reasons.impersonation',
                  ),
                  onPressed: onReasonSelected,
                ),
                SizedBox(height: modalActionSpacing),
                ProfileReportReasonButton(
                  reason: UserReportReason.changedMind,
                  label: translator.translate(
                    'components.user_report_modal.reasons.changed_mind',
                  ),
                  isSecondary: true,
                  onPressed: onReasonSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
