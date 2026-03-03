import 'package:cloudless/core/features/auth/domain/providers/sign_in_provider.dart';
import 'package:cloudless/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/otp/otp_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';

typedef SignInFormResult = ({
  FormerGroup form,
  AsyncCallback submit,
  ValueNotifier<bool> isSubmitting,
  ValueNotifier<bool> isPrivacyAccepted,
});

enum SignInFormKey { phoneNumber }

extension SignInFormKeyExtension on SignInFormKey {
  String get value => switch (this) {
    SignInFormKey.phoneNumber => 'phoneNumber',
  };
}

SignInFormResult useSignInForm(WidgetRef ref) {
  final isPrivacyAccepted = useState<bool>(false);
  String? phoneNumberValue;

  final formResult = useForm<void>(
    controls: {
      SignInFormKey.phoneNumber.value: FormerControl<String>(
        validators: [FormerValidators.required()],
      ),
    },
    onSubmit: (values) async {
      final rawPhone = values[SignInFormKey.phoneNumber.value] as String;
      // Strip all non-digit/+ chars and validate minimum length
      // E.164: + country code (1-3 digits) + subscriber (min ~4 digits)
      final sanitized = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
      final digitsOnly = sanitized.replaceAll('+', '');
      if (digitsOnly.length < 7) {
        throw FormatException('Invalid phone number: $rawPhone');
      }
      phoneNumberValue = sanitized.startsWith('+')
          ? sanitized
          : '+$sanitized';

      final result = await ref.read(signInProvider(phoneNumberValue!).future);
      return result;
    },
    onSuccess: (success) {
      logger.info('Sign in success');

      router.push(OtpRoutable(phoneNumber: phoneNumberValue!));
    },
    onFailure: (form, error) {
      final handled = CommonSupabaseExceptionUIHandler()
          .handleSupabaseException(context: ref.context, exception: error);

      if (!handled) {
        logger.error(
          'Sign in failed: unknown error',
          exception: error,
        );
        MainAlert.showGenericError(context: ref.context);
      }
    },
  );

  return (
    form: formResult.form,
    submit: formResult.submit,
    isSubmitting: formResult.isSubmitting,
    isPrivacyAccepted: isPrivacyAccepted,
  );
}
