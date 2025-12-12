import 'dart:io';

import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/too_many_requests_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/profile/data/exceptions/profile_avatar_upload_failed_exception.dart';
import 'package:cloudless/core/features/profile/data/exceptions/profile_unauthorized_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadAvatarExceptionsMapper {
  static MainException fromSupabaseException(Exception e) {
    // Storage-specific exceptions
    if (e is StorageException) {
      switch (e.message) {
        case 'Unauthorized':
          return const ProfileUnauthorizedException('Storage access denied');

        case 'PayloadTooLarge':
          return const ProfileAvatarUploadFailedException(
            'Avatar file is too large',
          );

        case 'TooManyClients':
          return const TooManyRequestsException(
            'Too many upload requests, please try again later',
          );

        default:
          return ProfileAvatarUploadFailedException(
            'Avatar upload failed: ${e.message}',
          );
      }
    }

    // PostgrestException for JWT issues during storage operations
    if (e is PostgrestException) {
      switch (e.code) {
        case '42501':
          return ProfileUnauthorizedException(e.code ?? '42501');

        default:
          return UnhandledException(
            'Avatar upload database error: ${e.message}',
            code: e.code,
            cause: e,
          );
      }
    }

    // File system errors
    if (e is FileSystemException) {
      return ProfileAvatarUploadFailedException(
        'File access error: ${e.message}',
      );
    }

    // Image processing errors
    if (e is FormatException) {
      return const ProfileAvatarUploadFailedException(
        'Invalid image file format',
      );
    }

    // Input validation errors
    if (e is ArgumentError) {
      return UnhandledException(
        'Invalid avatar upload parameters provided',
        cause: e,
      );
    }

    // Fallback for any other exception type
    return UnhandledException('Avatar upload error occurred', cause: e);
  }
}
