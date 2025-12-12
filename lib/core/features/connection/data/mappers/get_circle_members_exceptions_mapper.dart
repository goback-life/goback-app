import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/connection_unauthorized_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/get_circle_members_failed_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GetCircleMembersExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is PostgrestException) {
      switch (e.code) {
        // RLS policy violation
        case '42501':
          return ConnectionUnauthorizedException(e.code);

        // Invalid query parameters
        case 'PGRST100':
          return UnhandledException(
            'Invalid circle members query parameters: ${e.message}',
            code: e.code,
            cause: e,
          );

        // All other PostgrestException errors
        default:
          return UnhandledException(
            'Circle members retrieval failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // Data parsing errors (from JSON response)
    if (e is FormatException) {
      return UnhandledException(
        'Invalid circle members data format received',
        cause: e,
      );
    }

    if (e is TypeError) {
      return UnhandledException('Circle members data type mismatch', cause: e);
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid parameters provided for circle members retrieval',
        cause: e,
      );
    }

    // Fallback for any other exception type
    return const GetCircleMembersFailedException();
  }
}
