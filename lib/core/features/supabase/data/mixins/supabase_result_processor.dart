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
      return switch (result) {
        Success(value: final data) => await _mapSuccess(data, responseMapper),
        Failure(error: final error) => _mapFailure<T>(error, exceptionMapper),
      };
    } catch (exception) {
      return Failure(_wrapUnexpected(exception));
    } finally {
      onAfter?.call();
    }
  }

  Future<Result<T>> _mapSuccess<R, T>(
    R data,
    Future<T> Function(R) mapper,
  ) async {
    try {
      return Success(await mapper(data));
    } catch (exception) {
      return Failure(_wrapUnexpected(exception));
    }
  }

  Result<T> _mapFailure<T>(
    Object error,
    Exception Function(Exception) exceptionMapper,
  ) {
    // Detect wrapped network errors (e.g. AuthRetryableFetchException
    // containing SocketException or host lookup failures)
    if (error is Exception) {
      final message = _extractMessage(error);
      if (message.contains('SocketException') ||
          message.toLowerCase().contains('failed host lookup')) {
        return const Failure(NetworkConnectionException());
      }
    }

    return switch (error) {
      AuthException(statusCode: '401') => Failure(
        AuthSessionExpiredException(error.statusCode),
      ),
      AuthException(statusCode: '403') => Failure(
        AuthAccessDeniedException(error.statusCode),
      ),
      AuthException(statusCode: '429') => const Failure(
        TooManyRequestsException('Too many authentication requests'),
      ),

      PostgrestException(code: 'PGRST301') => const Failure(
        AuthSessionExpiredException('PGRST301'),
      ),
      PostgrestException(code: 'PGRST302') => const Failure(
        AuthAuthenticationRequiredException('PGRST302'),
      ),

      SocketException() => const Failure(NetworkConnectionException()),
      TimeoutException() => const Failure(RequestTimeoutException()),

      // Supabase-specific exceptions: check rate limits then delegate
      AuthApiException() ||
      PostgrestException() ||
      AuthException() ||
      StorageException() =>
        _handleSupabaseException<T>(error as Exception, exceptionMapper),

      Exception() => Failure(error),
      _ => Failure(UnhandledException('Unknown error occurred', cause: error)),
    };
  }

  Result<T> _handleSupabaseException<T>(
    Exception exception,
    Exception Function(Exception) exceptionMapper,
  ) {
    if (_isRateLimitingException(exception)) {
      return Failure(TooManyRequestsException(_extractMessage(exception)));
    }
    try {
      return Failure(exceptionMapper(exception));
    } catch (_) {
      return Failure(
        UnhandledException(
          'Error occurred during exception mapping',
          cause: exception,
        ),
      );
    }
  }

  bool _isRateLimitingException(Exception exception) {
    // AuthException (non-API) has statusCode
    if (exception is AuthException && exception is! AuthApiException) {
      return exception.statusCode == '429';
    }
    // AuthApiException and others: check message patterns
    final message = _extractMessage(exception).toLowerCase();
    return _rateLimitPatterns.any(message.contains);
  }

  String _extractMessage(Exception exception) {
    return switch (exception) {
      AuthApiException(message: final m) => m,
      AuthException(message: final m) => m,
      PostgrestException(message: final m) => m,
      StorageException(message: final m) => m,
      _ => exception.toString(),
    };
  }

  Exception _wrapUnexpected(Object exception) {
    return exception is Exception
        ? exception
        : UnhandledException('Unexpected error occurred', cause: exception);
  }
}
