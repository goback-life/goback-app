import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/profile/data/exceptions/profile_unauthorized_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GetProfileExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is PostgrestException) {
      switch (e.code) {
        // RLS policy violation
        case '42501':
          return ProfileUnauthorizedException(e.code);

        // Invalid query parameters
        case 'PGRST100':
          return UnhandledException(
            'Invalid profile query parameters: ${e.message}',
            code: e.code,
            cause: e,
          );

        // All other PostgrestException errors
        default:
          return UnhandledException(
            'Profile retrieval failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // Data parsing errors (from JSON response)
    if (e is FormatException) {
      return UnhandledException(
        'Invalid profile data format received',
        cause: e,
      );
    }

    if (e is TypeError) {
      return UnhandledException('Profile data type mismatch', cause: e);
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid user ID provided for profile retrieval',
        cause: e,
      );
    }

    // Fallback for any other exception type
    return UnhandledException('Profile retrieval error occurred', cause: e);
  }
}
