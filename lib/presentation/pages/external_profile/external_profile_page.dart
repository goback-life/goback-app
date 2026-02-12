import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_layout.dart';
import 'package:cloudless/presentation/pages/external_profile/views/external_profile_view.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_actions_menu.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class ExternalProfilePage extends HookConsumerWidget
    with MainLayout, ExternalProfileLayout {
  const ExternalProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMenuVisible = useState(false);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topMargin),
              MainAppBar(
                title: translator.translate('pages.external_profile.title'),
                rightWidget: MainAppBar.customAction(
                  icon: Assets.svg.menu.render(colorFilter: colorScheme.onSurface.asSrcIn),
                  onTap: () => isMenuVisible.value = !isMenuVisible.value,
                ),
              ),
              SizedBox(height: titleToImage),
              ExternalProfileView(userId: userId),
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
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: ProfileActionsMenu(
                  userId: userId,
                  showRemoveOption: false,
                  onActionCompleted: () => isMenuVisible.value = false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
