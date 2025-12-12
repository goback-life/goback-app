import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CreateProfileButton extends StatelessWidget
    with MainLayout, CreateProfileLayout {
  const CreateProfileButton({
    required this.onSubmit,
    required this.isEnabled,
    super.key,
  });

  final VoidCallback onSubmit;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FormerFormConsumer(
      builder: (context, formGroup, child) {
        final isFormValid = formGroup.valid;
        final canSubmit = isFormValid && isEnabled;

        return CallToAction.primary.filled(
          action: canSubmit ? onSubmit : null,
          label: Text(
            translator.translate('pages.create_profile.button'),
            style: textTheme.titleLarge?.copyWith(
              color: canSubmit ? colorScheme.primary : colorScheme.outline,
            ),
          ),
        );
      },
    );
  }
}
