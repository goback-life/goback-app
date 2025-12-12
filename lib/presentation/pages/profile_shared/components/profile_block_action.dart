import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/remove_connection_provider.dart';
import 'package:cloudless/core/features/profile/domain/enums/user_report_reason.dart';
import 'package:cloudless/core/features/profile/domain/providers/report_user_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/profile_shared/profile_actions_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Menu action for blocking a user.
/// This action will report the user and remove them from the circle.
class ProfileBlockAction extends HookConsumerWidget
    with MainLayout, ProfileActionsLayout {
  const ProfileBlockAction({
    required this.blockedUserId,
    required this.onActionCompleted,
    super.key,
  });

  final String blockedUserId;
  final VoidCallback onActionCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isBlocking = useState(false);

    return GestureDetector(
      onTap: isBlocking.value ? null : () => _handleBlock(context, ref),
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
              child: Center(
                child: SizedBox(
                  width: menuIconSize - 5,
                  height: menuIconSize - 5,
                  child: Assets.svg.close.render(
                    colorFilter: colorScheme.error.asSrcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: menuIconSpacing),
            Text(
              translator.translate('components.profile_actions_menu.block'),
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

  Future<void> _handleBlock(BuildContext context, WidgetRef ref) async {
    final textTheme = Theme.of(context).textTheme;

    await MainAlert.showFull(
      context: context,
      title: translator.translate('components.block_user.confirmation_title'),
      content: Text(
        translator.translate('components.block_user.confirmation_content'),
      ),
      primaryButtonText: translator.translate('components.block_user.confirm'),
      textButtonStyle: textTheme.bodyMedium,
      secondaryButtonText: translator.translate('components.block_user.cancel'),
      onPrimaryPressed: () async {
        router.pop();
        await _executeBlock(context, ref);
      },
      onSecondaryPressed: () {
        router.pop();
        onActionCompleted();
      },
    );
  }

  Future<void> _executeBlock(BuildContext context, WidgetRef ref) async {
    final currentUserAsync = ref.read(getCurrentUserProvider);
    final userId = currentUserAsync.whenOrNull(
      data: (userResult) => userResult.fold((user) => user.id, (error) => null),
    );

    if (userId == null) {
      if (context.mounted) {
        await MainAlert.showError(
          context: context,
          title: translator.translate('components.block_user.error_title'),
          content: translator.translate('components.block_user.error_content'),
        );
      }
      onActionCompleted();
      return;
    }

    // Report the user with 'blocked' reason
    final reportResult = await ref.read(
      reportUserProvider(
        reportedUserId: blockedUserId,
        reportedBy: userId,
        reason: UserReportReason.blocked,
      ).future,
    );

    // Remove the user from the circle (regardless of report result)
    final removeResult = await ref.read(
      removeConnectionProvider(blockedUserId).future,
    );

    // Invalidate circle members to refresh the UI
    ref.invalidate(getCircleMembersProvider);

    if (!context.mounted) {
      onActionCompleted();
      return;
    }

    // Check results and show appropriate message
    var blockSuccess = false;
    reportResult.fold((_) => blockSuccess = true, (_) {});
    removeResult.fold((_) => blockSuccess = true, (_) {});

    if (blockSuccess) {
      MainSnackbar.showSuccess(
        context,
        translator.translate('components.block_user.success_content'),
      );
      // Navigate back since the user was blocked
      router.pop();
    } else {
      await MainAlert.showError(
        context: context,
        title: translator.translate('components.block_user.error_title'),
        content: translator.translate('components.block_user.error_content'),
      );
    }

    onActionCompleted();
  }
}
