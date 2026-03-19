import 'package:cloudless/core/features/auth/domain/hooks/use_sign_in_form.dart';
import 'package:cloudless/presentation/components/form_field/input_decoration.dart';
import 'package:cloudless/presentation/components/form_field/phone_number_form_field.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/sign_in/components/sign_in_button.dart';
import 'package:cloudless/presentation/pages/sign_in/components/sign_in_privacy_checkbox.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:flutter/material.dart';

class SignInView extends HookConsumerWidget with MainLayout, SignInLayout {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signInResult = useSignInForm(ref);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    useLoadingOverlay(signInResult.isSubmitting);

    // Listen to phone number changes to detect US numbers
    useEffect(() {
      final phoneControl = signInResult.form.control<String>(
        SignInFormKey.phoneNumber.value,
      );
      final sub = phoneControl.valueChanges.listen((value) {
        if (value == null) return;
        final sanitized = value.replaceAll(RegExp(r'[^\d+]'), '');
        final normalized = sanitized.startsWith('+')
            ? sanitized
            : '+$sanitized';
        signInResult.isUsPhoneNumber.value = normalized.startsWith('+1');
      });
      return sub.cancel;
    }, const []);

    return FormerForm(
      form: signInResult.form,
      child: Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PhoneNumberFormField(),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<bool>(
                          valueListenable: signInResult.isUsPhoneNumber,
                          builder: (context, isUs, child) {
                            if (isUs) {
                              return Column(
                                children: [
                                  const Text(
                                    'US phone numbers require email verification.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: MainFontFamilies.quicksand,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: MainColors.grey500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _EmailField(
                                    form: signInResult.form,
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        SizedBox(height: verticalSpacing),
                        ValueListenableBuilder<bool>(
                          valueListenable: signInResult.isPrivacyAccepted,
                          builder: (context, isAccepted, child) {
                            return SignInPrivacyCheckbox(
                              value: isAccepted,
                              onChanged: (value) {
                                if (value != null) {
                                  signInResult.isPrivacyAccepted.value = value;
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomMargin),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: signInResult.isPrivacyAccepted,
                    builder: (context, isPrivacyAccepted, child) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: signInResult.isSubmitting,
                        builder: (context, isSubmitting, child) {
                          return SignInButton(
                            onSubmit: signInResult.submit,
                            isEnabled: isPrivacyAccepted && !isSubmitting,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.form,
    required this.colorScheme,
    required this.textTheme,
  });

  final FormerGroup form;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      config: const GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: 47,
        tint: MainColors.accent,
      ),
      child: TextField(
        onChanged: (value) {
          form.control<String>(SignInFormKey.email.value).updateValue(value);
        },
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        cursorColor: colorScheme.tertiary,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        decoration: inputDecoration(context, '').copyWith(
          hintText: 'Email address',
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
