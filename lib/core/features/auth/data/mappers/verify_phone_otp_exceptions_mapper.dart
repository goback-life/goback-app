import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_invalid_verification_code_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_otp_expired_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_phone_exists_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_already_exists_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_banned_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyOtpExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'otp_expired':
          return AuthOtpExpiredException(e.code);
        case 'invalid_credentials':
          return AuthInvalidVerificationCodeException(e.code);
        case 'user_not_found':
          return AuthUserNotFoundException(e.code);
        case 'phone_exists':
          return AuthPhoneExistsException(e.code);
        case 'user_already_exists':
          return AuthUserAlreadyExistsException(e.code);
        case 'user_banned':
          return AuthUserBannedException(e.code);
        default:
          return UnhandledException(
            'OTP verification failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    if (e is ArgumentError) {
      return UnhandledException('Invalid OTP verification data', cause: e);
    }

    return UnhandledException('OTP verification error occurred', cause: e);
  }
}
