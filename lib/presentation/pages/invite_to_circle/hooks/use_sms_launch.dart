import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_create_invite_code.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SendInviteCallback = Future<void> Function(ContactModel contact);

class InviteSendingState {
  const InviteSendingState({
    required this.sendInvite,
    required this.isLoading,
    required this.selectedContactName,
    required this.error,
    required this.clearError,
  });

  final SendInviteCallback sendInvite;
  final bool isLoading;
  final String selectedContactName;
  final String? error;
  final VoidCallback clearError;
}

InviteSendingState useSmsSender(WidgetRef ref) {
  final createInviteCode = useCreateInviteCode(ref);
  final isLoading = useState<bool>(false);
  final selectedContactName = useState<String>('');
  final error = useState<String?>(null);
  final context = useContext();

  Future<void> sendInvite(ContactModel contact) async {
    if (contact.primaryPhoneNumber == null) {
      return;
    }

    isLoading.value = true;
    selectedContactName.value = contact.displayName;
    error.value = null;

    final currentUserResult = await ref.read(getCurrentUserProvider.future);

    final currentUser = await currentUserResult.fold((user) async => user, (
      error,
    ) {
      logger.error('Failed to get current user', exception: error);
    });

    final profileResult = await ref.read(
      getProfileProvider(currentUser!.id).future,
    );

    final currentProfile = await profileResult.fold(
      (profile) async => profile,
      (error) {
        logger.error('Failed to get current user profile', exception: error);
      },
    );

    if (currentProfile == null) {
      logger.error('Current user profile not found');
    }

    final result = await createInviteCode();

    await result.fold(
      (inviteCode) async {
        final message = translator.translate(
          'pages.invite_to_circle.sms_message',
          arguments: {'code': inviteCode, 'username': currentProfile!.username},
        );

        final phoneNumber = contact.primaryPhoneNumber!.replaceAll(
          RegExp(r'[^\d+]'),
          '',
        );
        final encodedMessage = Uri.encodeComponent(message);
        final smsUrl = 'sms:$phoneNumber?body=$encodedMessage';

        final Uri uri = Uri.parse(smsUrl);
        bool launched = false;

        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        if (!launched) {
          logger.error('Cannot launch SMS app');
        } else {
          if (context.mounted) {
            MainSnackbar.showSuccess(
              context,
              translator.translate('pages.invite_to_circle.success_message'),
            );
            // Don't pop immediately - let the user see the success message
            // when they return from the SMS app
          }
        }
      },
      (failure) {
        error.value = translator.translate(
          'pages.invite_to_circle.code_generation_failed',
        );
      },
    );

    isLoading.value = false;
    selectedContactName.value = '';
  }

  void clearError() {
    error.value = null;
  }

  return InviteSendingState(
    sendInvite: sendInvite,
    isLoading: isLoading.value,
    selectedContactName: selectedContactName.value,
    error: error.value,
    clearError: clearError,
  );
}
