/// Defines the contract for the logger repository.
///
/// Any implementation of this contract must provide methods to log messages
/// at various severity levels.
abstract class LoggerRepositoryContract {
  /// Logs a general message.
  void log(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  });

  /// Logs an informational message.
  void logInfo(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  });

  /// Logs a warning message.
  void logWarning(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  });

  /// Logs an error message.
  void logError(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  });

  /// Logs a critical message.
  void logCritical(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  });

  /// Logs router action.
  void logRouterAction(
      String action, String? name, Map<String, dynamic>? extraData);
}
