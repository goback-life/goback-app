import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_create_invite_code.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SendInviteCallback = Future<void> Function(ContactModel contact);
typedef ShareInviteCallback = Future<void> Function();

class InviteSendingState {
  const InviteSendingState({
    required this.sendInvite,
    required this.shareInvite,
    required this.isLoading,
    required this.selectedContactName,
    required this.error,
    required this.clearError,
  });

  final SendInviteCallback sendInvite;
  final ShareInviteCallback shareInvite;
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

  /// Generates an invite code and returns the message, or null on failure.
  Future<String?> _generateInviteMessage() async {
    isLoading.value = true;
    error.value = null;

    final currentUserResult = await ref.read(getCurrentUserProvider.future);

    if (!context.mounted) return null;

    final currentUser = await currentUserResult.fold((user) async => user, (
      error,
    ) {
      logger.error('Failed to get current user', exception: error);
    });

    final profileResult = await ref.read(
      getProfileProvider(currentUser!.id).future,
    );

    if (!context.mounted) return null;

    final currentProfile = await profileResult.fold(
      (profile) async => profile,
      (error) {
        logger.error('Failed to get current user profile', exception: error);
      },
    );

    if (currentProfile == null) {
      logger.error('Current user profile not found');
      return null;
    }

    final result = await createInviteCode();

    if (!context.mounted) return null;

    String? message;
    result.fold(
      (inviteCode) {
        message = translator.translate(
          'pages.invite_to_circle.sms_message',
          arguments: {'code': inviteCode, 'username': currentProfile.username},
        );
      },
      (failure) {
        error.value = translator.translate(
          'pages.invite_to_circle.code_generation_failed',
        );
      },
    );

    return message;
  }

  /// Sends invite via SMS to a specific contact.
  Future<void> sendInvite(ContactModel contact) async {
    if (contact.primaryPhoneNumber == null) return;

    selectedContactName.value = contact.displayName;
    final message = await _generateInviteMessage();

    if (message == null) {
      isLoading.value = false;
      selectedContactName.value = '';
      return;
    }

    final phoneNumber = contact.primaryPhoneNumber!.replaceAll(
      RegExp(r'[^\d+]'),
      '',
    );
    final encodedMessage = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:$phoneNumber&body=$encodedMessage');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      if (context.mounted) {
        MainSnackbar.showSuccess(
          context,
          translator.translate('pages.invite_to_circle.success_message'),
        );
      }
    } else {
      logger.error('Cannot launch SMS app');
    }

    isLoading.value = false;
    selectedContactName.value = '';
  }

  /// Opens the native share sheet with the invite message.
  Future<void> shareInvite() async {
    final message = await _generateInviteMessage();

    if (message == null) {
      isLoading.value = false;
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromCenter(
            center: MediaQuery.of(context).size.center(Offset.zero),
            width: 100,
            height: 100,
          );

    final shareResult = await SharePlus.instance.share(
      ShareParams(text: message, sharePositionOrigin: origin),
    );

    if (shareResult.status == ShareResultStatus.success && context.mounted) {
      MainSnackbar.showSuccess(
        context,
        translator.translate('pages.invite_to_circle.success_message'),
      );
    }

    isLoading.value = false;
  }

  void clearError() {
    error.value = null;
  }

  return InviteSendingState(
    sendInvite: sendInvite,
    shareInvite: shareInvite,
    isLoading: isLoading.value,
    selectedContactName: selectedContactName.value,
    error: error.value,
    clearError: clearError,
  );
}
