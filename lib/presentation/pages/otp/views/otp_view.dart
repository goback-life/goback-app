import 'package:cloudless/core/features/auth/domain/hooks/use_otp_form.dart';
import 'package:cloudless/presentation/components/form_field/otp_form_field.dart';
import 'package:cloudless/presentation/pages/otp/components/otp_button.dart';
import 'package:cloudless/presentation/pages/otp/components/otp_description.dart';
import 'package:cloudless/presentation/pages/otp/components/otp_resend_code.dart';
import 'package:cloudless/presentation/pages/otp/otp_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:cloudless/presentation/utilities/phone_number_formatter.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class OtpView extends HookConsumerWidget with MainLayout, OtpLayout {
  const OtpView({required this.phoneNumber, this.email = '', super.key});

  final String phoneNumber;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final isEmailFlow = email.isNotEmpty;
    final otpFormResult = useOtpForm(ref, phoneNumber, email: email);

    useLoadingOverlay(otpFormResult.isSubmitting);

    final displayTarget = isEmailFlow
        ? email
        : PhoneNumberFormatter.format(phoneNumber);

    return FormerForm(
      form: otpFormResult.form,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        translator.translate('pages.otp.title'),
                        style: textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: titleToText),
                      OtpDescription(
                        number: displayTarget,
                        text: translator.translate('pages.otp.description'),
                      ),
                      SizedBox(height: descriptionToFormField),
                      const OtpFormField(),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomMargin),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: OtpResendCode(
                        onResendCode: otpFormResult.resendCode,
                      ),
                    ),
                    SizedBox(height: resendCodeToButton),
                    ValueListenableBuilder<bool>(
                      valueListenable: otpFormResult.isSubmitting,
                      builder: (context, isSubmitting, child) {
                        return OtpButton(
                          onSubmit: otpFormResult.submit,
                          isEnabled: !isSubmitting,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
