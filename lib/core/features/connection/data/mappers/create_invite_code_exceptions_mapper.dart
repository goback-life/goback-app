import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/connection_unauthorized_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_code_generation_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_limit_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/invite_code_creation_failed_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateInviteCodeExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    if (e is PostgrestException) {
      switch (e.code) {
        // RLS policy violation
        case '42501':
          return ConnectionUnauthorizedException(e.code);

        // Duplicate invite code
        case '23505':
          return UnhandledException(
            'Duplicate invite code generated: ${e.message}',
            code: e.code,
            cause: e,
          );

        // Check constraint violation (could be invite limit)
        case '23514':
          return const InviteLimitException('Maximum active invites reached');

        // Invalid query parameters
        case 'PGRST100':
          return UnhandledException(
            'Invalid invite creation parameters: ${e.message}',
            code: e.code,
            cause: e,
          );

        // All other PostgrestException errors
        default:
          return UnhandledException(
            'Invite code creation failed: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // Custom exceptions
    if (e is InviteLimitException) {
      return e;
    }

    if (e is InviteCodeGenerationException) {
      return const InviteCodeCreationFailedException();
    }

    // Data parsing errors
    if (e is FormatException) {
      return UnhandledException(
        'Invalid invite code format received',
        cause: e,
      );
    }

    if (e is TypeError) {
      return UnhandledException('Invite code data type mismatch', cause: e);
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid invite code creation parameters provided',
        cause: e,
      );
    }

    // Fallback for any other exception type
    return UnhandledException('Invite code creation error occurred', cause: e);
  }
}
