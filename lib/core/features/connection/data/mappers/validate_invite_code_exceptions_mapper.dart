import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/connection_unauthorized_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_code_invalid_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_code_validation_failed_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/invite_code_expired_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/target_user_circle_size_limit_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/user_circle_size_limit_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ValidateInviteCodeExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is PostgrestException) {
      switch (e.code) {
        // RLS policy violation
        case '42501':
          return ConnectionUnauthorizedException(e.code);

        // Foreign key violation - invalid invite code
        case '23503':
          return InviteCodeInvalidException(e.code ?? 'unknown');

        // Custom check constraint for expired codes
        case '23514':
          return InviteCodeExpiredException(e.code ?? 'unknown');

        // Invalid query parameters
        case 'PGRST100':
          return UnhandledException(
            'Invalid invite code validation parameters: ${e.message}',
            code: e.code,
            cause: e,
          );

        // No rows returned
        case 'PGRST116':
          return UnhandledException(
            'Unexpected invite code validation response: ${e.message}',
            code: e.code,
            cause: e,
          );

        // All other PostgrestException errors
        default:
          return UnhandledException(
            'Invite code validation failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // Data parsing errors
    if (e is FormatException) {
      return UnhandledException(
        'Invalid invite code validation data format received',
        cause: e,
      );
    }

    if (e is TypeError) {
      return UnhandledException(
        'Invite code validation data type mismatch',
        cause: e,
      );
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid invite code provided for validation',
        cause: e,
      );
    }

    // Circle size limit exceptions
    if (e is UserCircleSizeLimitException) {
      return e;
    }

    if (e is TargetUserCircleSizeLimitException) {
      return e;
    }

    // Fallback for any other exception type
    return const InviteCodeValidationFailedException();
  }
}
