import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/pages/profile/views/profile_view.dart';
import 'package:cloudless/presentation/pages/settings/settings_routable.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class ProfilePage extends HookConsumerWidget with MainLayout, ProfileLayout {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topMargin),
          MainAppBar(
            title: translator.translate('pages.profile.title'),
            rightWidget: MainAppBar.customAction(
              icon: Assets.svg.settings.render(colorFilter: colorScheme.onSurface.asSrcIn),
              onTap: () => router.push(const SettingsRoutable()),
            ),
          ),
          SizedBox(height: titleToImage),
          const ProfileView(),
        ],
      ),
    );
  }
}
