import 'package:cloudless/core/features/connection/domain/hooks/use_remove_connection.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/circle_profile/views/circle_profile_view.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_hamburger_menu.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_actions_menu.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CircleProfilePage extends HookConsumerWidget
    with MainLayout, ProfileLayout {
  const CircleProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / designWidth;
    final removeConnection = useRemoveConnection(ref);
    final isRemoving = useState(false);
    final isMenuVisible = useState(false);

    Future<void> handleRemoveConnection() async {
      if (isRemoving.value) return;
      isRemoving.value = true;
      final result = await removeConnection(userId);
      result.fold(
        (success) {
          ref.invalidate(getCircleMembersProvider);
          router.pop();
        },
        (error) {
          MainAlert.showError(
            context: context,
            title: translator.translate('components.alert.remove_error.title'),
            content: translator.translate(
              'components.alert.remove_error.content',
            ),
          );
        },
      );
    }

    void showRemoveConfirmation() {
      isMenuVisible.value = false;
      MainAlert.showFull(
        context: context,
        title: translator.translate(
          'components.alert.remove_confirmation.title',
        ),
        content: Text(
          translator.translate('components.alert.remove_confirmation.content'),
        ),
        primaryButtonText: translator.translate(
          'components.alert.remove_confirmation.confirm',
        ),
        secondaryButtonText: translator.translate(
          'components.alert.remove_confirmation.cancel',
        ),
        onPrimaryPressed: () async {
          router.pop();
          await handleRemoveConnection();
        },
        onSecondaryPressed: () => router.pop(),
      );
    }

    return Scaffold(
      backgroundColor: MainColors.dark,
      body: Stack(
        children: [
          CircleProfileView(userId: userId, scale: s),

          // Hamburger menu button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + hamburgerTopOffset * s,
            right: hamburgerRightOffset * s,
            child: ProfileHamburgerMenu(
              scale: s,
              onTap: () => isMenuVisible.value = !isMenuVisible.value,
            ),
          ),

          // Dismiss scrim
          if (isMenuVisible.value)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => isMenuVisible.value = false,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Actions dropdown
          if (isMenuVisible.value)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  hamburgerTopOffset * s +
                  40,
              right: hamburgerRightOffset * s,
              child: Material(
                color: Colors.transparent,
                child: ProfileActionsMenu(
                  userId: userId,
                  showRemoveOption: true,
                  onRemoveTap: showRemoveConfirmation,
                  onActionCompleted: () => isMenuVisible.value = false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
