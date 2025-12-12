import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/configs/logger_config.dart';
import 'package:dedecube_logger/src/data/providers/logger_config_provider.dart';
import 'package:dedecube_logger/src/domain/contracts/logger_contract.dart';
import 'package:dedecube_logger/src/domain/providers/log_critical_provider.dart';
import 'package:dedecube_logger/src/domain/providers/log_error_provider.dart';
import 'package:dedecube_logger/src/domain/providers/log_info_provider.dart';
import 'package:dedecube_logger/src/domain/providers/log_provider.dart';
import 'package:dedecube_logger/src/domain/providers/log_router_action_provider.dart';
import 'package:dedecube_logger/src/domain/providers/log_warning_provider.dart';

/// A [Logger] class to handle logging operations.
///
/// This class provides methods to log messages at different severity levels
/// and allows updating the logging configuration dynamically.
class Logger implements LoggerContract {
  /// Creates a [Logger] instance with the initial [LoggerConfig].
  ///
  /// - Initializes the logger with the provided [config].
  /// - Invalidates the [loggerConfigNotifierProvider] to ensure the new configuration
  ///   is propagated to all listeners.
  Logger(
    this._config,
  ) {
    riverpodContainer()
        .read(loggerConfigNotifierProvider.notifier)
        .loggerConfig = _config;
  }

  LoggerConfig _config;

  /// Gets the current [LoggerConfig].
  ///
  /// Provides access to the current logging configuration.
  @override
  LoggerConfig get config => _config;

  /// Sets a new [LoggerConfig].
  ///
  /// - Updates the internal configuration.
  /// - Invalidates the [loggerConfigNotifierProvider] to notify all listeners of the change.
  @override
  set config(LoggerConfig config) {
    _config = config;
    riverpodContainer()
        .read(loggerConfigNotifierProvider.notifier)
        .loggerConfig = _config;
  }

  /// Logs a general message.
  ///
  /// - [message]: The message to log.
  /// - [arguments]: Additional contextual information.
  /// - [exception]: An exception to log.
  /// - [stackTrace]: The stack trace associated with the exception.
  @override
  void log(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    riverpodContainer().read(
      logProvider(
        message,
        arguments: arguments,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Logs an informational message.
  ///
  /// - [message]: The informational message to log.
  /// - [arguments]: Additional contextual information.
  /// - [exception]: An exception to log.
  /// - [stackTrace]: The stack trace associated with the exception.
  @override
  void info(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    riverpodContainer().read(
      logInfoProvider(
        message,
        arguments: arguments,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Logs a warning message.
  ///
  /// - [message]: The warning message to log.
  /// - [arguments]: Additional contextual information.
  /// - [exception]: An exception to log.
  /// - [stackTrace]: The stack trace associated with the exception.
  @override
  void warning(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    riverpodContainer().read(
      logWarningProvider(
        message,
        arguments: arguments,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Logs an error message.
  ///
  /// - [message]: The error message to log.
  /// - [arguments]: Additional contextual information.
  /// - [exception]: An exception to log.
  /// - [stackTrace]: The stack trace associated with the exception.
  @override
  void error(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    riverpodContainer().read(
      logErrorProvider(
        message,
        arguments: arguments,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Logs a critical message.
  ///
  /// - [message]: The critical message to log.
  /// - [arguments]: Additional contextual information.
  /// - [exception]: An exception to log.
  /// - [stackTrace]: The stack trace associated with the exception.
  @override
  void critical(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    riverpodContainer().read(
      logCriticalProvider(
        message,
        arguments: arguments,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  void routerAction(
    String action,
    String? name,
    Map<String, dynamic>? extraData,
  ) {
    riverpodContainer().read(
      logRouterActionProvider(
        action,
        name,
        extraData,
      ),
    );
  }
}

LoggerContract get logger => GetIt.I.get<LoggerContract>();
