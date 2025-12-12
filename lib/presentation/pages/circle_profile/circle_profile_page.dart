import 'package:cloudless/core/features/connection/domain/hooks/use_remove_connection.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_layout.dart';
import 'package:cloudless/presentation/pages/circle_profile/views/circle_profile_view.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_actions_menu.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CircleProfilePage extends HookConsumerWidget
    with MainLayout, CircleProfileLayout {
  const CircleProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final removeConnection = useRemoveConnection(ref);
    final isRemoving = useState(false);
    final isMenuVisible = useState(false);

    Future<void> handleRemoveConnection() async {
      if (isRemoving.value) {
        return;
      }

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
        textButtonStyle: textTheme.bodyMedium,
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
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topMargin),
              MainAppBar(
                title: translator.translate('pages.circle_profile.title'),
                rightWidget: MainAppBar.customAction(
                  icon: Assets.svg.menu.render(),
                  onTap: () => isMenuVisible.value = !isMenuVisible.value,
                ),
              ),
              SizedBox(height: titleToImage),
              CircleProfileView(userId: userId),
            ],
          ),
          if (isMenuVisible.value)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => isMenuVisible.value = false,
                child: Container(color: Colors.transparent),
              ),
            ),
          if (isMenuVisible.value)
            Positioned(
              top: topMargin + 40,
              right: horizontalPadding,
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
