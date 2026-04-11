import 'package:cloudless/core/exceptions/main_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/notification/data/exceptions/notification_fetch_exception.dart';
import 'package:cloudless/core/features/notification/data/exceptions/notification_network_exception.dart';
import 'package:cloudless/core/features/notification/data/exceptions/notification_unauthorized_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationExceptionMapper {
  static MainException fromSupabaseException(Exception exception) {
    return switch (exception) {
      // Auth/Authorization errors
      PostgrestException(code: '401') =>
        const NotificationUnauthorizedException(),
      PostgrestException(code: '403') =>
        const NotificationUnauthorizedException(),
      PostgrestException(code: '42501') =>
        const NotificationUnauthorizedException(),

      // Not found
      PostgrestException(code: '404', :final message) =>
        NotificationFetchException(message),

      // Network and server errors
      PostgrestException(code: '500') => const NotificationNetworkException(),
      PostgrestException(code: '502') => const NotificationNetworkException(),
      PostgrestException(code: '503') => const NotificationNetworkException(),

      // Invalid query parameters
      PostgrestException(code: 'PGRST100', :final message) =>
        UnhandledException(
          'Invalid notification query parameters: $message',
          code: 'PGRST100',
          cause: exception,
        ),

      // Generic PostgrestException
      PostgrestException(:final code, :final message) => UnhandledException(
        'Notification retrieval failed: $message',
        code: code,
        cause: exception,
      ),

      // Data parsing errors
      FormatException() => UnhandledException(
        'Invalid notification data format received',
        cause: exception,
      ),
      TypeError() => UnhandledException(
        'Notification data type mismatch',
        cause: exception,
      ),

      // Input validation errors
      ArgumentError() => UnhandledException(
        'Invalid parameters provided for notification retrieval',
        cause: exception,
      ),

      // Fallback
      _ => NotificationFetchException(exception.toString()),
    };
  }
}
