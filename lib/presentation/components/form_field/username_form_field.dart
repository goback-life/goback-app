import 'package:cloudless/core/features/profile/domain/enums/profile_form_item.dart';
import 'package:cloudless/presentation/components/form_field/custom_text_selection_controls.dart';
import 'package:cloudless/presentation/components/form_field/input_decoration.dart';
import 'package:cloudless/presentation/hooks/use_debounced_username_check.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class UsernameFormField extends HookConsumerWidget
    with MainLayout, CreateProfileLayout {
  const UsernameFormField({
    required this.usernameCheckResult,
    super.key,
    this.controller,
  });

  final TextEditingController? controller;
  final DebouncedUsernameResult usernameCheckResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasEverFocused = useState(false);

    return FormerFormConsumer(
      builder: (context, form, child) {
        final control = form.control<String>(ProfileFormItem.username.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translator.translate('pages.create_profile.username'),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus && !hasEverFocused.value) {
                  hasEverFocused.value = true;
                }
              },
              child: FormerFormTextfield<String>(
                textCapitalization: TextCapitalization.sentences,
                selectionControls: CustomTextSelectionControls(),
                autocorrect: false,
                onTapOutside: (event) => context.unfocus(),
                cursorColor: colorScheme.tertiary,
                control: control,
                textInputAction: TextInputAction.next,
                maxLength: 30,
                onSubmitted: (control) => form.focus('biography'),
                decoration: inputDecoration(context, ''),
                controller: controller,
                showErrors: (control) {
                  if (control.hasFocus) {
                    return control.invalid && control.dirty;
                  } else {
                    return hasEverFocused.value && control.invalid;
                  }
                },
                validationMessages: {
                  'required': (_) => translator.translate(
                    'pages.create_profile.error.username_required',
                  ),
                  'minLength': (_) => translator.translate(
                    'pages.create_profile.error.username_too_short',
                  ),
                  'pattern': (_) => translator.translate(
                    'pages.create_profile.error.username_invalid',
                  ),
                  translator.translate(
                    'pages.create_profile.error.username_invalid',
                  ): (_) => translator.translate(
                    'pages.create_profile.error.username_invalid',
                  ),
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
