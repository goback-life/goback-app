import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/post/data/exceptions/feed_post_anauthorized_exceptions.dart';
import 'package:cloudless/core/features/post/data/exceptions/feed_post_fetch_exceptions.dart';
import 'package:cloudless/core/features/post/data/exceptions/feed_post_network_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedPostExceptionMapper {
  static MainException fromSupabaseException(Exception exception) {
    return switch (exception) {
      // Auth/Authorization errors
      PostgrestException(code: '401') => const FeedPostUnauthorizedException(),
      PostgrestException(code: '403') => const FeedPostUnauthorizedException(),
      PostgrestException(code: '42501') =>
        const FeedPostUnauthorizedException(),

      // Not found
      PostgrestException(code: '404', :final message) => FeedPostFetchException(
        message,
      ),

      // Network and server errors
      PostgrestException(code: '500') => const FeedPostNetworkException(),
      PostgrestException(code: '502') => const FeedPostNetworkException(),
      PostgrestException(code: '503') => const FeedPostNetworkException(),

      // Invalid query parameters
      PostgrestException(code: 'PGRST100', :final message) =>
        UnhandledException(
          'Invalid feed query parameters: $message',
          code: 'PGRST100',
          cause: exception,
        ),

      // Generic PostgrestException
      PostgrestException(:final code, :final message) => UnhandledException(
        'Feed retrieval failed: $message',
        code: code,
        cause: exception,
      ),

      // Data parsing errors
      FormatException() => UnhandledException(
        'Invalid feed data format received',
        cause: exception,
      ),
      TypeError() => UnhandledException(
        'Feed data type mismatch',
        cause: exception,
      ),

      // Input validation errors
      ArgumentError() => UnhandledException(
        'Invalid parameters provided for feed retrieval',
        cause: exception,
      ),

      // Fallback
      _ => FeedPostFetchException(exception.toString()),
    };
  }
}
