import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/connection_already_exists_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/connection_unauthorized_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_code_invalid_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/cannot_use_own_invite_code_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/invite_code_expired_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/join_circle_failed_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/target_user_circle_size_limit_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/user_circle_size_limit_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JoinCircleExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is PostgrestException) {
      // Check for circle size limit exceptions in message first (from database function)
      if (e.message.contains('User has reached maximum circle size')) {
        return const UserCircleSizeLimitException();
      }
      if (e.message.contains('Creator has reached maximum circle size')) {
        return const TargetUserCircleSizeLimitException();
      }

      switch (e.code) {
        // RLS policy violation
        case '42501':
          return ConnectionUnauthorizedException(e.code);

        // Check constraint - cannot use own invite code
        case '23514':
          return const CannotUseOwnInviteCodeException();

        // Unique constraint - already connected
        case '23505':
          return ConnectionAlreadyExistsException(e.code ?? 'unknown');

        // Foreign key violation - invalid invite code
        case '23503':
          return InviteCodeInvalidException(e.code ?? 'unknown');

        // Custom constraint for expired codes
        case '23513':
          return InviteCodeExpiredException(e.code ?? 'unknown');

        // Invalid query parameters
        case 'PGRST100':
          return UnhandledException(
            'Invalid circle join parameters: ${e.message}',
            code: e.code,
            cause: e,
          );

        // All other PostgrestException errors
        default:
          return UnhandledException(
            'Circle join operation failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // Data parsing errors
    if (e is FormatException) {
      return UnhandledException(
        'Invalid circle join data format received',
        cause: e,
      );
    }

    if (e is TypeError) {
      return UnhandledException('Circle join data type mismatch', cause: e);
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid invite code provided for circle join',
        cause: e,
      );
    }

    // Circle size limit exceptions (from application layer)
    if (e is UserCircleSizeLimitException) {
      return e;
    }

    if (e is TargetUserCircleSizeLimitException) {
      return e;
    }

    // Fallback for any other exception type
    return const JoinCircleFailedException();
  }
}
