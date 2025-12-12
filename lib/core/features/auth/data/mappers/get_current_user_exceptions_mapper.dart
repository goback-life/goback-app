import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_refresh_token_already_used_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_refresh_token_not_found_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_expired_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_not_found_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_banned_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GetCurrentUserExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is AuthUserNotFoundException) {
      return const AuthUserNotFoundException();
    }

    if (e is AuthException) {
      switch (e.code) {
        case 'session_expired':
          return AuthSessionExpiredException(e.code);
        case 'session_not_found':
          return AuthSessionNotFoundException(e.code);
        case 'refresh_token_not_found':
          return AuthRefreshTokenNotFoundException(e.code);
        case 'refresh_token_already_used':
          return AuthRefreshTokenAlreadyUsedException(e.code);
        case 'user_banned':
          return AuthUserBannedException(e.code);
        default:
          return UnhandledException(
            'Get current user failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    if (e is ArgumentError) {
      return UnhandledException('Invalid user session data', cause: e);
    }

    return UnhandledException('Get current user error occurred', cause: e);
  }
}
