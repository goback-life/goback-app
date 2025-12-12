import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/domain/enums/user_report_reason.dart';
import 'package:cloudless/core/features/profile/domain/exceptions/user_report_exception.dart';
import 'package:cloudless/core/features/profile/domain/providers/report_user_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_report_reason_modal.dart';
import 'package:cloudless/presentation/pages/profile_shared/profile_actions_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Menu action for reporting a user profile.
class ProfileReportAction extends HookConsumerWidget
    with MainLayout, ProfileActionsLayout {
  const ProfileReportAction({
    required this.reportedUserId,
    required this.onActionCompleted,
    super.key,
  });

  final String reportedUserId;
  final VoidCallback onActionCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _handleReport(context, ref),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: menuItemHorizontalPadding,
          vertical: menuItemVerticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: menuIconSize,
              height: menuIconSize,
              child: Assets.svg.alert.render(),
            ),
            SizedBox(width: menuIconSpacing),
            Text(
              translator.translate('components.profile_actions_menu.report'),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReport(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (dialogContext) => ProfileReportReasonModal(
        onReasonSelected: (reason) async {
          router.pop();

          final currentUserAsync = ref.read(getCurrentUserProvider);
          final userId = currentUserAsync.whenOrNull(
            data: (userResult) =>
                userResult.fold((user) => user.id, (error) => null),
          );

          if (userId == null) {
            if (context.mounted) {
              await MainAlert.showError(
                context: context,
                title: translator.translate(
                  'components.report_user.error_title',
                ),
                content: translator.translate(
                  'components.report_user.error_content',
                ),
              );
            }
            onActionCompleted();
            return;
          }

          if (reason == UserReportReason.changedMind) {
            onActionCompleted();
            return;
          }

          final result = await ref.read(
            reportUserProvider(
              reportedUserId: reportedUserId,
              reportedBy: userId,
              reason: reason,
            ).future,
          );

          result.fold(
            (_) {
              onActionCompleted();

              if (context.mounted) {
                MainSnackbar.showSuccess(
                  context,
                  translator.translate(
                    'components.report_user.success_content',
                  ),
                );
              }
            },
            (error) async {
              if (!context.mounted) {
                onActionCompleted();
                return;
              }

              if (error is UserReportException &&
                  error.code == 'REPORT_ALREADY_EXISTS') {
                await MainAlert.showError(
                  context: context,
                  title: translator.translate(
                    'components.report_user.already_reported_title',
                  ),
                  content: translator.translate(
                    'components.report_user.already_reported_content',
                  ),
                );
              } else {
                await MainAlert.showError(
                  context: context,
                  title: translator.translate(
                    'components.report_user.error_title',
                  ),
                  content: translator.translate(
                    'components.report_user.error_content',
                  ),
                );
              }

              onActionCompleted();
            },
          );
        },
      ),
    );
  }
}
