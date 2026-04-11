import 'package:cloudless/core/features/auth/domain/hooks/use_sign_in_form.dart';
import 'package:cloudless/presentation/components/form_field/custom_text_selection_controls.dart';
import 'package:cloudless/presentation/components/form_field/input_decoration.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

class PhoneNumberFormField extends HookConsumerWidget
    with MainLayout, SignInLayout {
  const PhoneNumberFormField({super.key, this.controller});

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          focusNode.requestFocus();
        }
      });
      return null;
    }, []);

    return FormerFormConsumer(
      builder: (context, form, child) {
        final phoneValue =
            form.control<String>(SignInFormKey.phoneNumber.value).value ?? '';
        final phoneControl = form.control<String>(
          SignInFormKey.phoneNumber.value,
        );

        PhoneController phoneController;
        if (phoneValue.isNotEmpty) {
          try {
            phoneController = PhoneController(
              initialValue: PhoneNumber.parse(phoneValue),
            );
          } catch (e) {
            // If parsing fails, use the default initial value
            final initialValue = translator.translate(
              'pages.sign_in.initial_phone_value',
            );
            try {
              phoneController = PhoneController(
                initialValue: PhoneNumber.parse(initialValue),
              );
            } catch (e) {
              phoneController = PhoneController();
            }
          }
        } else {
          // No phone value, use the default initial value from translations
          final initialValue = translator.translate(
            'pages.sign_in.initial_phone_value',
          );
          try {
            phoneController = PhoneController(
              initialValue: PhoneNumber.parse(initialValue),
            );
          } catch (e) {
            phoneController = PhoneController();
          }
        }

        return AppGlassContainer(
          config: const GlassConfig(
            variant: GlassVariant.regular,
            cornerRadius: 47,
            tint: MainColors.accent,
          ),
          child: Theme(
            data: theme.copyWith(
              textTheme: theme.textTheme,
              appBarTheme: const AppBarTheme(
                backgroundColor: MainColors.dark,
                foregroundColor: MainColors.white,
              ),
            ),
            child: PhoneFormField(
              autovalidateMode: AutovalidateMode.disabled,
              selectionControls: CustomTextSelectionControls(),
              countrySelectorNavigator: const CountrySelectorNavigator.page(),
              focusNode: focusNode,
              onTapOutside: (event) => context.unfocus(),
              controller: phoneController,
              cursorColor: colorScheme.tertiary,
              decoration: inputDecoration(context, ''),
              validator: PhoneValidator.compose([
                PhoneValidator.required(
                  context,
                  errorText: translator.translate(
                    'pages.sign_in.error.phone_required',
                  ),
                ),
                PhoneValidator.validMobile(
                  context,
                  errorText: translator.translate(
                    'pages.sign_in.error.phone_invalid',
                  ),
                ),
                // Custom validator to check form-level errors
                (PhoneNumber? phoneNumber) {
                  if (phoneControl.hasError('invalid_phone')) {
                    return translator.translate(
                      'pages.sign_in.error.phone_invalid',
                    );
                  }
                  return null;
                },
              ]),
              onChanged: (PhoneNumber? phoneNumber) {
                final phoneControl = form.control<String>(
                  SignInFormKey.phoneNumber.value,
                );
                final phoneValue = phoneNumber?.international ?? '';

                phoneControl.updateValue(phoneValue);

                // Clear any previous validation errors when user changes input
                if (phoneControl.hasError('invalid_phone')) {
                  phoneControl.setErrors({});
                }

                // Validate the phone number and set form-level error if invalid
                if (phoneValue.isNotEmpty && phoneNumber != null) {
                  try {
                    final isValidPhone =
                        PhoneValidator.validMobile(
                          context,
                          errorText: translator.translate(
                            'pages.sign_in.error.phone_invalid',
                          ),
                        ).call(phoneNumber) ==
                        null;

                    if (!isValidPhone) {
                      phoneControl.setErrors({'invalid_phone': true});
                    }
                  } catch (e) {
                    phoneControl.setErrors({'invalid_phone': true});
                  }
                }
              },
              isCountrySelectionEnabled: true,
              isCountryButtonPersistent: true,
              countryButtonStyle: CountryButtonStyle(
                showDialCode: true,
                showIsoCode: false,
                showFlag: true,
                textStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
