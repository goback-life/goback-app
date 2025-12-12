import 'package:cloudless/core/features/auth/domain/hooks/use_sign_in_form.dart';
import 'package:cloudless/presentation/components/form_field/phone_number_form_field.dart';
import 'package:cloudless/presentation/pages/sign_in/components/sign_in_button.dart';
import 'package:cloudless/presentation/pages/sign_in/components/sign_in_privacy_checkbox.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_presentation/widgets/layout/bottomed_list_view.dart';
import 'package:flutter/material.dart';

class SignInView extends HookConsumerWidget with MainLayout, SignInLayout {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signInResult = useSignInForm(ref);

    useLoadingOverlay(signInResult.isSubmitting);

    return FormerForm(
      form: signInResult.form,
      child: Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: BottomedListView(
            useSafeArea: true,
            bottom: Padding(
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
            children: [
              const PhoneNumberFormField(),
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
              SizedBox(height: bottomMargin),
            ],
          ),
        ),
      ),
    );
  }
}
