import 'package:dedecube_logger/src/data/configs/logger_config.dart';

/// A contract for the Logger class, defining the required methods and properties.
abstract class LoggerContract {
  /// Gets the current [LoggerConfig].
  LoggerConfig get config;

  /// Sets a new [LoggerConfig].
  set config(LoggerConfig config);

  /// Logs a message with the specified severity level.
  ///
  /// - [message]: The message to log.
  /// - [exception]: An optional exception related to the log message.
  /// - [stackTrace]: An optional stack trace related to the log message.
  /// - [arguments]: Optional additional arguments to include in the log.
  void log(
    String message, {
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? arguments,
  });

  /// Logs an informational message.
  ///
  /// - [message]: The message to log.
  /// - [exception]: An optional exception related to the log message.
  /// - [stackTrace]: An optional stack trace related to the log message.
  /// - [arguments]: Optional additional arguments to include in the log.
  void info(
    String message, {
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? arguments,
  });

  /// Logs a warning message.
  ///
  /// - [message]: The message to log.
  /// - [exception]: An optional exception related to the log message.
  /// - [stackTrace]: An optional stack trace related to the log message.
  /// - [arguments]: Optional additional arguments to include in the log.
  void warning(
    String message, {
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? arguments,
  });

  /// Logs an error message.
  ///
  /// - [message]: The message to log.
  /// - [exception]: An optional exception related to the log message.
  /// - [stackTrace]: An optional stack trace related to the log message.
  /// - [arguments]: Optional additional arguments to include in the log.
  void error(
    String message, {
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? arguments,
  });

  /// Logs a critical message.
  ///
  /// - [message]: The message to log.
  /// - [exception]: An optional exception related to the log message.
  /// - [stackTrace]: An optional stack trace related to the log message.
  /// - [arguments]: Optional additional arguments to include in the log.
  void critical(
    String message, {
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? arguments,
  });

  /// Logs an action performed by a router.
  ///
  /// [action] The name of the action performed.
  /// [name] An optional route name associated with the action.
  /// [extraData] An optional map containing additional data related to the action.
  void routerAction(
    String action,
    String? name,
    Map<String, dynamic>? extraData,
  );
}
