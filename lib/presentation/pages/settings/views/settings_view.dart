import 'package:cloudless/presentation/pages/settings/components/account_section.dart';
import 'package:cloudless/presentation/pages/settings/components/assistance_legal_section.dart';
import 'package:cloudless/presentation/pages/settings/components/logout_button.dart';
import 'package:cloudless/presentation/pages/settings/components/preferences_section.dart';
import 'package:cloudless/presentation/pages/settings/settings_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class SettingsView extends HookConsumerWidget with MainLayout, SettingsLayout {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: BottomedListView(
        useSafeArea: true,
        bottom: Padding(
          padding: EdgeInsets.only(bottom: bottomMargin),
          child: const LogoutButton(),
        ),
        children: [
          const AccountSection(),
          SizedBox(height: verticalMargin),
          const PreferencesSection(),
          SizedBox(height: verticalMargin),
          const AssistanceLegalSection(),
          SizedBox(height: verticalSpacing),
        ],
      ),
    );
  }
}
