import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/connection_not_found_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/connection_unauthorized_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/remove_connection_failed_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoveConnectionExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is PostgrestException) {
      switch (e.code) {
        // RLS policy violation
        case '42501':
          return ConnectionUnauthorizedException(e.code);

        // Foreign key violation - connection not found
        case '23503':
          return ConnectionNotFoundException(e.code ?? 'unknown');

        // Invalid query parameters
        case 'PGRST100':
          return UnhandledException(
            'Invalid connection removal parameters: ${e.message}',
            code: e.code,
            cause: e,
          );

        // No rows affected
        case 'PGRST116':
          return UnhandledException(
            'No connection found to remove: ${e.message}',
            code: e.code,
            cause: e,
          );

        // All other PostgrestException errors
        default:
          return UnhandledException(
            'Connection removal failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // Data parsing errors
    if (e is FormatException) {
      return UnhandledException(
        'Invalid connection removal data format received',
        cause: e,
      );
    }

    if (e is TypeError) {
      return UnhandledException(
        'Connection removal data type mismatch',
        cause: e,
      );
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid user ID provided for connection removal',
        cause: e,
      );
    }

    // Fallback for any other exception type
    return const RemoveConnectionFailedException();
  }
}
