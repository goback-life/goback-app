import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_phone_not_confirmed_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_expired_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResendOtpExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'user_not_found':
          return AuthUserNotFoundException(e.code);
        case 'phone_not_confirmed':
          return AuthPhoneNotConfirmedException(e.code);
        case 'session_expired':
          return AuthSessionExpiredException(e.code);
        default:
          return UnhandledException(
            'Resend OTP failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    if (e is ArgumentError) {
      return UnhandledException('Invalid phone number provided', cause: e);
    }

    return UnhandledException('Resend OTP error occurred', cause: e);
  }
}
