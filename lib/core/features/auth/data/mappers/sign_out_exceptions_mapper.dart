import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_refresh_token_not_found_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_not_found_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignOutExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'session_not_found':
          return AuthSessionNotFoundException(e.code);
        case 'refresh_token_not_found':
          return AuthRefreshTokenNotFoundException(e.code);
        default:
          return UnhandledException(
            'Sign out failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    return UnhandledException('Sign out error occurred', cause: e);
  }
}
