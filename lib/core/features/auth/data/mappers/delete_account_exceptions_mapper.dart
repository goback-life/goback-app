import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_user_not_found_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteAccountExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'user_not_found':
          return const AuthUserNotFoundException();
        default:
          return UnhandledException(
            'Delete account failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    return UnhandledException('Delete account error occurred', cause: e);
  }
}
