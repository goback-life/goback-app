/// Defines the severity levels for logging.
///
/// These levels determine the importance and verbosity of log messages.
enum LogSeverity {
  /// General log messages.
  log,

  /// Informational messages, typically used for tracking the flow of the application.
  info,

  /// Warning messages, indicating potential issues that do not halt execution.
  warning,

  /// Error messages, indicating issues that have caused the current operation to fail.
  error,

  /// Critical messages, indicating severe issues that may compromise the system's integrity.
  critical;

  /// Converts a string representation of a log severity to a [LogSeverity] enum value.
  static LogSeverity fromString(String? value) {
    if (value == null) {
      return LogSeverity.log;
    }
    switch (value.toLowerCase()) {
      case 'critical':
        return LogSeverity.critical;
      case 'error':
        return LogSeverity.error;
      case 'warning':
        return LogSeverity.warning;
      case 'info':
        return LogSeverity.info;
      default:
        return LogSeverity.log;
    }
  }
}
