import 'dart:async';
import 'dart:io';

import 'package:cloudless/core/exceptions/network_connection_exception.dart';
import 'package:cloudless/core/exceptions/request_timeout_exception.dart';
import 'package:cloudless/core/exceptions/too_many_requests_exception.dart';
import 'package:cloudless/core/exceptions/unhandled_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_access_denied_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_authentication_required_exception.dart';
import 'package:cloudless/core/features/auth/data/exceptions/auth_session_expired_exception.dart';
import 'package:cloudless/core/features/supabase/domain/contracts/supabase_result_processor_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

mixin SupabaseResultProcessor implements SupabaseResultProcessorContract {
  static const _rateLimitPatterns = {
    'too many requests',
    'rate limit',
    'sms rate limit exceeded',
    'rate_limit',
    'too_many_requests',
    'resend_rate_limit',
    'wait before resending',
    'cooldown',
  };

  /// Executes a Supabase request with unified error handling and response mapping.
  ///
  /// Type parameters:
  /// - [R]: Raw response type from Supabase
  /// - [T]: Target mapped type
  ///
  /// Parameters:
  /// - [request]: Function that executes the Supabase call
  /// - [responseMapper]: Transforms successful response [R] to target type [T]
  /// - [exceptionMapper]: Maps Supabase exceptions to domain exceptions
  /// - [onBefore]: Optional pre-request callback
  /// - [onAfter]: Optional post-request callback (always executed)
  @override
  FutureResult<T> processSupabaseResult<R, T>({
    required FutureResult<R> Function() request,
    required Future<T> Function(R) responseMapper,
    required Exception Function(Exception) exceptionMapper,
    void Function()? onBefore,
    void Function()? onAfter,
  }) async {
    onBefore?.call();

    try {
      final result = await request();
      return await _processResult(result, responseMapper, exceptionMapper);
    } catch (exception) {
      return Failure(_handleUnexpectedException(exception));
    } finally {
      onAfter?.call();
    }
  }

  /// Processes the result from the Supabase request
  Future<Result<T>> _processResult<R, T>(
    Result<R> result,
    Future<T> Function(R) responseMapper,
    Exception Function(Exception) exceptionMapper,
  ) async {
    return switch (result) {
      Success(value: final data) => await _mapSuccessfulResponse(
        data,
        responseMapper,
      ),
      Failure(error: final error) => _mapFailedResponse<T>(
        error,
        exceptionMapper,
      ),
    };
  }

  /// Maps a successful response to the target type
  Future<Result<T>> _mapSuccessfulResponse<R, T>(
    R data,
    Future<T> Function(R) mapper,
  ) async {
    try {
      final mappedData = await mapper(data);
      return Success(mappedData);
    } catch (exception) {
      return Failure(_handleUnexpectedException(exception));
    }
  }

  /// Maps a failed response using the appropriate exception handler
  Result<T> _mapFailedResponse<T>(
    Object error,
    Exception Function(Exception) exceptionMapper,
  ) {
    // Check for wrapped network errors first (e.g., AuthRetryableFetchException
    // that contains SocketException or host lookup failures)
    if (error is Exception) {
      final message = _extractExceptionMessage(error);
      if (message.contains('SocketException') ||
          message.toLowerCase().contains('failed host lookup')) {
        return const Failure(NetworkConnectionException());
      }
    }

    return switch (error) {
      // Critical auth errors
      AuthException(statusCode: '401') => Failure(_mapCriticalAuthError(error)),
      AuthException(statusCode: '403') => Failure(_mapCriticalAuthError(error)),

      // Rate limiting - handled centrally
      AuthException(statusCode: '429') => const Failure(
        TooManyRequestsException('Too many authentication requests'),
      ),

      // JWT/Session errors (common across all features)
      PostgrestException(code: 'PGRST301') => const Failure(
        AuthSessionExpiredException('PGRST301'),
      ),
      PostgrestException(code: 'PGRST302') => const Failure(
        AuthAuthenticationRequiredException('PGRST302'),
      ),

      // Network and connectivity exceptions
      SocketException() => const Failure(NetworkConnectionException()),

      TimeoutException() => const Failure(RequestTimeoutException()),

      // Supabase-specific exceptions - delegate to feature mappers
      AuthApiException() => _handleSupabaseException<T>(
        error as Exception,
        exceptionMapper,
      ),
      PostgrestException() => _handleSupabaseException<T>(
        error as Exception,
        exceptionMapper,
      ),
      AuthException() => _handleSupabaseException<T>(
        error as Exception,
        exceptionMapper,
      ),
      StorageException() => _handleSupabaseException<T>(
        error as Exception,
        exceptionMapper,
      ),

      // Other known exceptions
      Exception() => Failure(error),

      // Unknown error types
      _ => Failure(UnhandledException('Unknown error occurred', cause: error)),
    };
  }

  /// Maps critical auth errors that are common across all features
  Exception _mapCriticalAuthError(Object error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '401':
          return AuthSessionExpiredException(error.statusCode);
        case '403':
          return AuthAccessDeniedException(error.statusCode);
        default:
          return UnhandledException(
            'Auth error: ${error.message}',
            code: error.statusCode,
            cause: error,
          );
      }
    }

    return UnhandledException('Authentication failed', cause: error);
  }

  /// Checks if the exception is related to rate limiting
  bool _isRateLimitingException(Exception exception) {
    // Check AuthException and AuthApiException status code first
    if (exception is AuthException) {
      return exception.statusCode == '429';
    }

    if (exception is AuthApiException) {
      // AuthApiException doesn't have statusCode, so check message
      final message = exception.message.toLowerCase();
      return _rateLimitPatterns.any((pattern) => message.contains(pattern));
    }

    // For other exceptions, check message patterns
    final message = _extractExceptionMessage(exception).toLowerCase();
    return _rateLimitPatterns.any((pattern) => message.contains(pattern));
  }

  /// Handles Supabase-specific exceptions with rate limit detection
  Result<T> _handleSupabaseException<T>(
    Exception exception,
    Exception Function(Exception) exceptionMapper,
  ) {
    // Check for rate limiting patterns first
    if (_isRateLimitingException(exception)) {
      final message = _extractExceptionMessage(exception);
      return Failure(TooManyRequestsException(message));
    }

    // Delegate to feature-specific mapper
    return _mapExceptionSafely<T>(exception, exceptionMapper);
  }

  /// Extracts the message from various Supabase exception types
  String _extractExceptionMessage(Exception exception) {
    return switch (exception) {
      AuthApiException(message: final message) => message,
      AuthException(message: final message) => message,
      PostgrestException(message: final message) => message,
      StorageException(message: final message) => message,
      _ => exception.toString(),
    };
  }

  /// Safely maps an exception using the provided mapper
  Result<T> _mapExceptionSafely<T>(
    Exception exception,
    Exception Function(Exception) exceptionMapper,
  ) {
    try {
      final mappedException = exceptionMapper(exception);
      return Failure(mappedException);
    } catch (mappingException) {
      return Failure(
        UnhandledException(
          'Error occurred during exception mapping',
          cause: exception,
        ),
      );
    }
  }

  /// Handles unexpected exceptions that occur during processing
  Exception _handleUnexpectedException(Object exception) {
    return exception is Exception
        ? exception
        : UnhandledException('Unexpected error occurred', cause: exception);
  }
}
