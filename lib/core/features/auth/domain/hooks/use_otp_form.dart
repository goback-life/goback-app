import 'package:cloudless/core/features/auth/data/exceptions/auth_access_denied_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_invalid_verification_code_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_banned_exception.dart';
import 'package:cloudless/core/features/auth/domain/hooks/use_resend_phone_otp.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/is_authenticated_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/verify_phone_otp_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/push_notification_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/scheduled_notification_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/has_completed_profile_provider.dart';
import 'package:cloudless/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_routable.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';

typedef OtpFormResult = ({
  FormerGroup form,
  AsyncCallback submit,
  ValueNotifier<bool> isSubmitting,
  Future<void> Function({bool showFeedback}) resendCode,
});

enum OtpFormKey { otp }

extension OtpFormKeyExtension on OtpFormKey {
  String get value => switch (this) {
    OtpFormKey.otp => 'otp',
  };
}

OtpFormResult useOtpForm(WidgetRef ref, String phoneNumber) {
  final resendOtpCallback = useResendPhoneOtp(ref, phoneNumber);

  final formResult = useForm<bool>(
    controls: {
      OtpFormKey.otp.value: FormerControl<String>(
        validators: [
          FormerValidators.required(),
          FormerValidators.minLength(6),
          FormerValidators.maxLength(6),
        ],
      ),
    },
    onSubmit: (values) async {
      final code = values[OtpFormKey.otp.value] as String;
      return ref.read(verifyPhoneOtpProvider(phoneNumber, code).future);
    },
    onSuccess: (success) async {
      // Invalidate auth + profile providers to prevent stale cached results.
      // isAuthenticatedProvider is kept alive by NavOverlayWrapper and will
      // otherwise still return false when the middleware checks it.
      ref.invalidate(isAuthenticatedProvider);
      ref.invalidate(getCurrentUserProvider);
      ref.invalidate(hasCompletedProfileProvider);

      // Register FCM token + set up message listeners
      await ref.read(pushNotificationProvider).initialize();

      // Schedule daily local notifications
      await ref.read(scheduledNotificationProvider).initialize();

      try {
        final hasCompletedProfileResult = await ref.read(
          hasCompletedProfileProvider.future,
        );

        hasCompletedProfileResult.fold(
          (hasCompleted) {
            if (hasCompleted) {
              router.go(const HomeRoutable());
            } else {
              router.go(const CreateProfileRoutable());
            }
          },
          (error) {
            router.go(const CreateProfileRoutable());
          },
        );
      } catch (_) {
        router.go(const CreateProfileRoutable());
      }
    },
    onFailure: (form, error) {
      form.control(OtpFormKey.otp.value).setErrors({'invalid': true});

      final handled = CommonSupabaseExceptionUIHandler()
          .handleSupabaseException(context: ref.context, exception: error);

      if (!handled) {
        switch (error) {
          case AuthUserBannedException():
            logger.error('OTP verification: user is banned');
            MainAlert.showSimple(
              context: ref.context,
              title: translator.translate('pages.otp.alert.banned.title'),
              content: translator.translate('pages.otp.alert.banned.content'),
            );
            break;

          case AuthInvalidVerificationCodeException():
            logger.error('OTP verification: invalid or expired code');
            MainAlert.showSimple(
              context: ref.context,
              title: translator.translate('pages.otp.alert.invalid_code.title'),
              content: translator.translate(
                'pages.otp.alert.invalid_code.content',
              ),
            );
            break;

          case AuthAccessDeniedException():
            logger.error('OTP verification: access denied - invalid code');
            MainSnackbar.showError(
              ref.context,
              translator.translate('pages.otp.alert.invalid_code.content'),
            );
            break;

          default:
            logger.error('OTP verification: unknown error');
            MainAlert.showSimple(
              context: ref.context,
              title: translator.translate(
                'components.alert.generic_error.title',
              ),
              content: translator.translate(
                'components.alert.generic_error.content',
              ),
            );
        }
      }
    },
  );

  Future<void> handleResendCode({bool showFeedback = true}) async {
    await resendOtpCallback();
  }

  useEffect(() {
    final otpControl = formResult.form.control(OtpFormKey.otp.value);
    final sub = otpControl.valueChanges.listen((value) {
      if (otpControl.hasError('invalid')) {
        otpControl
          ..setErrors({})
          ..updateValueAndValidity();
      }
    });

    return sub.cancel;
  }, const []);

  return (
    form: formResult.form,
    submit: formResult.submit,
    isSubmitting: formResult.isSubmitting,
    resendCode: handleResendCode,
  );
}
