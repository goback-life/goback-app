import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/profile/data/exceptions/profile_unauthorized_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckUsernameAvailabilityExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is PostgrestException) {
      switch (e.code) {
        // RLS policy violation
        case '42501':
          return ProfileUnauthorizedException(e.code);

        default:
          return UnhandledException(
            'Username availability check failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid format for username provided for availability check',
        cause: e,
      );
    }

    // Fallback for any other exception type
    return UnhandledException(
      'Username availability check error occurred',
      cause: e,
    );
  }
}
