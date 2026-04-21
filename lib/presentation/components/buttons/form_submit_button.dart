import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:flutter/material.dart';

/// Shared submit button used across auth and profile forms.
///
/// Wraps [FormerFormConsumer] + [CallToAction.primary.filled] with a
/// consistent enabled/disabled style. Only the [labelText] differs per page.
class FormSubmitButton extends StatelessWidget {
  const FormSubmitButton({
    required this.onSubmit,
    required this.isEnabled,
    required this.labelText,
    super.key,
  });

  final VoidCallback onSubmit;
  final bool isEnabled;
  final String labelText;

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
            labelText,
            style: textTheme.titleLarge?.copyWith(
              color: canSubmit
                  ? MainColors.accent
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
