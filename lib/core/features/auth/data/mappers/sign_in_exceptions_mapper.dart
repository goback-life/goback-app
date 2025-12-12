import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_phone_not_confirmed_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_expired_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_banned_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'invalid_credentials':
          return UnhandledException(
            'Invalid phone number or password',
            code: e.code,
            cause: e,
          );
        case 'user_not_found':
          return AuthUserNotFoundException(e.code);
        case 'phone_not_confirmed':
          return AuthPhoneNotConfirmedException(e.code);
        case 'user_banned':
          return AuthUserBannedException(e.code);
        case 'session_expired':
          return AuthSessionExpiredException(e.code);
        default:
          return UnhandledException(
            'Sign in failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid sign in credentials provided',
        cause: e,
      );
    }

    return UnhandledException('Sign in error occurred', cause: e);
  }
}
