import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/media/domain/exceptions/invalid_media_exception.dart';
import 'package:cloudless/core/features/post/data/exceptions/create_post_failed_exception.dart';
import 'package:cloudless/core/features/post/data/exceptions/post_rate_limit_exception.dart';
import 'package:cloudless/core/features/post/data/exceptions/post_upload_failed_exception.dart';
import 'package:cloudless/core/features/post/domain/exceptions/post_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostExceptionsMapper {
  static MainException fromSupabaseException(Exception exception) {
    return switch (exception) {
      // Storage exceptions - Media upload errors
      StorageException(statusCode: '413') => const InvalidMediaException(
        'File too large',
      ),
      StorageException(statusCode: '415') => const InvalidMediaException(
        'Unsupported media type',
      ),
      StorageException(statusCode: '400') => const InvalidMediaException(
        'Invalid media file',
      ),
      StorageException(statusCode: '403') => const PostException(
        'Storage access denied',
      ),
      StorageException(statusCode: '404') => const PostException(
        'Storage bucket not found',
      ),
      StorageException(:final message) => PostUploadFailedException(message),

      // Rate limit exceeded (custom trigger error)
      PostgrestException(code: 'P0001', :final message)
          when message.contains('Rate limit exceeded') =>
        const PostRateLimitException(),

      // Database constraint violations
      PostgrestException(code: '23503', :final message) => UnhandledException(
        'Invalid reference data: $message',
        code: '23503',
        cause: exception,
      ),
      PostgrestException(code: '23505', :final message) => UnhandledException(
        'Duplicate post data: $message',
        code: '23505',
        cause: exception,
      ),
      PostgrestException(code: '23514', :final message) => UnhandledException(
        'Invalid post constraints: $message',
        code: '23514',
        cause: exception,
      ),
      PostgrestException(code: '23502', :final message) => UnhandledException(
        'Invalid foreign key reference: $message',
        code: '23502',
        cause: exception,
      ),

      // RLS policy violations
      PostgrestException(code: '42501') => const PostException(
        'Access denied',
        '42501',
      ),

      // Invalid column reference
      PostgrestException(code: '42703', :final message) => UnhandledException(
        'Invalid column reference: $message',
        code: '42703',
        cause: exception,
      ),

      // Invalid query parameters
      PostgrestException(code: 'PGRST100', :final message) =>
        UnhandledException(
          'Invalid post query parameters: $message',
          code: 'PGRST100',
          cause: exception,
        ),

      // Auth exceptions
      AuthException(statusCode: '401') => const PostException(
        'Authentication required',
        '401',
      ),
      AuthException(statusCode: '403') => const PostException(
        'Insufficient permissions',
        '403',
      ),

      // Generic PostgrestException
      PostgrestException(:final code, :final message) => UnhandledException(
        'Post creation failed: $message',
        code: code,
        cause: exception,
      ),

      // Data parsing errors
      FormatException() => UnhandledException(
        'Invalid post data format',
        cause: exception,
      ),
      TypeError() => UnhandledException(
        'Post data type mismatch',
        cause: exception,
      ),

      // Input validation errors
      ArgumentError() => UnhandledException(
        'Invalid parameters provided for post creation',
        cause: exception,
      ),

      // Fallback
      _ => const CreatePostFailedException(
        'An unexpected error occurred during post creation',
      ),
    };
  }
}
