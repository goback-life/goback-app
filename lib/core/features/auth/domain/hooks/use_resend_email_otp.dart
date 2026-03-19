import 'package:cloudless/core/features/auth/domain/providers/resend_email_otp_provider.dart';
import 'package:cloudless/core/features/supabase/data/handlers/common_supabase_exception_ui_handler.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';

AsyncCallback useResendEmailOtp(WidgetRef ref, String email) {
  return useCallback(() async {
    final response = await ref.read(resendEmailOtpProvider(email).future);

    response.fold(
      (_) {
        logger.info('Resend email otp success');
        MainSnackbar.showSuccess(
          ref.context,
          translator.translate('pages.verify_phone.snackbars.success'),
        );
      },
      (failure) {
        final handled = CommonSupabaseExceptionUIHandler()
            .handleSupabaseException(context: ref.context, exception: failure);

        if (!handled) {
          logger.error('Resend email otp failed: unknown error');
          MainSnackbar.showError(
            ref.context,
            translator.translate('pages.verify_phone.snackbars.error'),
          );
        }
      },
    );
  }, [ref, email]);
}
