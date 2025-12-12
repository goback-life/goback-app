import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_refresh_token_not_found_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_not_found_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ValidateSessionExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'user_not_found':
          return const AuthUserNotFoundException();
        case 'session_not_found':
          return AuthSessionNotFoundException(e.code);
        case 'invalid_grant':
          return AuthRefreshTokenNotFoundException(e.code);
        case 'refresh_token_not_found':
          return AuthRefreshTokenNotFoundException(e.code);
        default:
          return UnhandledException(
            'Session validation failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    return UnhandledException('Session validation error occurred', cause: e);
  }
}
