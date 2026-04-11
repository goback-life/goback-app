import 'package:cloudless/core/features/profile/domain/enums/profile_form_item.dart';
import 'package:cloudless/presentation/components/form_field/custom_text_selection_controls.dart';
import 'package:cloudless/presentation/components/form_field/input_decoration.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class DescriptionFormField extends HookConsumerWidget {
  const DescriptionFormField({super.key, this.onSubmitted, this.controller});

  final TextEditingController? controller;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasEverFocused = useState(false);

    return FormerFormConsumer(
      builder: (context, form, child) {
        final control = form.control<String>(ProfileFormItem.biography.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translator.translate('pages.create_profile.description'),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            AppGlassContainer(
              config: const GlassConfig(
                variant: GlassVariant.regular,
                cornerRadius: 16,
                tint: MainColors.accent,
              ),
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus && !hasEverFocused.value) {
                    hasEverFocused.value = true;
                  }
                },
                child: FormerFormTextfield<String>(
                  textCapitalization: TextCapitalization.sentences,
                  selectionControls: CustomTextSelectionControls(),
                  onTapOutside: (event) => context.unfocus(),
                  autocorrect: true,
                  cursorColor: colorScheme.tertiary,
                  control: control,
                  textInputAction: TextInputAction.newline,
                  maxLines: 5,
                  maxLength: 200,
                  onSubmitted: (control) {
                    if (onSubmitted != null) {
                      onSubmitted!();
                    } else {
                      form.unfocus();
                    }
                  },
                  decoration: inputDecoration(context, ''),
                  controller: controller,
                  showErrors: (control) {
                    if (control.hasFocus) {
                      return control.invalid && control.dirty;
                    } else {
                      return hasEverFocused.value && control.invalid;
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
