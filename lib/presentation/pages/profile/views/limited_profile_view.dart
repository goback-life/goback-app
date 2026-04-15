import 'package:cloudless/core/features/connection/domain/providers/connection_request_actions_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Simplified profile screen for distance-2 participants (friends-of-friends).
///
/// Shows avatar, @username, and an "Add to circle" button.
/// Navigated to when tapping a non-connected participant in post detail
/// or friends-locked-out list.
class LimitedProfileView extends HookConsumerWidget with MainLayout {
  const LimitedProfileView({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.contextType,
    this.contextId,
    super.key,
  });

  final String userId;
  final String username;
  final String? avatarUrl;

  /// Connection context (e.g. 'lockout') passed with the connection request.
  final String? contextType;

  /// Context reference ID (e.g. lockout session ID) passed with the request.
  final String? contextId;

  static const double _avatarSize = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSending = useState(false);
    final requestSent = useState(false);

    Future<void> sendRequest() async {
      if (isSending.value || requestSent.value) return;
      isSending.value = true;

      final result = await ref.read(
        sendConnectionRequestProvider(
          userId,
          contextType: contextType,
          contextId: contextId,
        ).future,
      );

      if (!context.mounted) return;

      result.fold(
        (status) {
          requestSent.value = true;
          final message = status == 'auto_accepted'
              ? '$username added to your circle!'
              : 'Request sent to @$username';
          MainSnackbar.showSuccess(context, message);
        },
        (error) {
          MainSnackbar.showError(context, 'Could not send request. Try again.');
        },
      );

      isSending.value = false;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                ProfileImage(
                  imageUrl: avatarUrl,
                  username: username,
                  size: _avatarSize,
                ),
                const SizedBox(height: 16),

                // Username
                Text(
                  '@$username',
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Add to circle button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: requestSent.value ? null : sendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: requestSent.value
                          ? Theme.of(context).colorScheme.outline
                          : MainColors.accent,
                      foregroundColor: MainColors.white,
                      disabledBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.outline,
                      disabledForegroundColor: MainColors.white.withValues(
                        alpha: 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSending.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: MainColors.white,
                            ),
                          )
                        : Text(
                            requestSent.value
                                ? 'Request sent'
                                : 'Add to circle',
                            style: const TextStyle(
                              fontFamily: MainFontFamilies.quicksand,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
