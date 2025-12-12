import 'package:dedecube_logger/src/data/enums/log_severity.dart';

/// Defines the contract for logger configuration.
abstract class LoggerConfigContract {
  /// The severity level of the logs.
  LogSeverity get logSeverity;

  /// Indicates whether logging is enabled.
  bool get isLogEnabled;

  /// Indicates whether logging for the http is enabled or not.
  bool get isHttpLogEnabled;
}
