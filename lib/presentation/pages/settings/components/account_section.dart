import 'package:cloudless/core/features/auth/domain/hooks/use_delete_account.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/settings/components/settings_menu_item.dart';
import 'package:cloudless/presentation/pages/settings/settings_layout.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class AccountSection extends HookConsumerWidget
    with MainLayout, SettingsLayout {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserAsync = ref.watch(getCurrentUserProvider);
    final deleteAccount = useDeleteAccount(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translator.translate('pages.settings.account'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.surfaceContainerHigh,
          ),
        ),
        SizedBox(height: titleSectionToElement),

        currentUserAsync.when(
          data: (userResult) => userResult.fold(
            (user) => _buildPhoneNumber(context, user.phoneNumber),
            (error) => _buildPhoneNumberError(context),
          ),
          loading: () => _buildPhoneNumberLoading(context),
          error: (_, __) => _buildPhoneNumberError(context),
        ),

        SizedBox(height: phoneNumberToDeleteAccount),

        SettingsMenuItem(
          icon: Assets.svg.deleteIcon.render(),
          title: translator.translate('pages.settings.delete_data'),
          onTap: () => _showDeleteAccountAlert(context, ref, deleteAccount),
        ),
      ],
    );
  }

  Widget _buildPhoneNumber(BuildContext context, String? phoneNumber) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RichText(
      text: TextSpan(
        text: translator.translate('pages.settings.phone_number'),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: phoneNumber ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberError(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RichText(
      text: TextSpan(
        text: translator.translate('pages.settings.phone_number'),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: translator.translate('pages.settings.phone_number_error'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberLoading(BuildContext context) {
    return const SizedBox.shrink();
  }

  void _showDeleteAccountAlert(
    BuildContext context,
    WidgetRef ref,
    DeleteAccountCallback deleteAccount,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    MainAlert.showFull(
      context: context,
      title: translator.translate('components.alert.delete_account.title'),
      content: Text(
        translator.translate('components.alert.delete_account.content'),
      ),
      primaryButtonText: translator.translate(
        'components.alert.delete_account.delete',
      ),
      textButtonStyle: textTheme.bodyMedium,
      secondaryButtonText: translator.translate(
        'components.alert.delete_account.cancel',
      ),
      onPrimaryPressed: () async {
        await deleteAccount();
        ref.invalidate(getProfileProvider);

        router.go(const SignInRoutable());
      },
      onSecondaryPressed: () => router.pop(),
    );
  }
}
