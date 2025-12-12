import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_layout.dart';
import 'package:cloudless/presentation/pages/create_profile/views/create_profile_view.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CreateProfilePage extends HookConsumerWidget
    with MainLayout, CreateProfileLayout {
  const CreateProfilePage({super.key});

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
          MainAppBar(title: translator.translate('pages.create_profile.title')),
          SizedBox(height: titleToImage),
          const CreateProfileView(),
        ],
      ),
    );
  }
}
