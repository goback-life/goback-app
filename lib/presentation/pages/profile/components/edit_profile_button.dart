import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/edit_profile/edit_profile_routable.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class EditProfileButton extends StatelessWidget with MainLayout, ProfileLayout {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CallToAction.primary.filled(
      action: () {
        router.push(const EditProfileRoutable());
      },
      label: Text(
        translator.translate('pages.profile.button'),
        style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
      ),
      horizontalMargin: horizontalMargin,
    );
  }
}
