/// Contract for Firebase Crashlytics service operations.
///
/// This interface defines the core functionality for crash reporting
/// and error tracking in the application.
abstract class CrashlyticsServiceContract {
  /// Logs a non-fatal error to Crashlytics.
  ///
  /// Use this to track exceptions that are caught and handled gracefully.
  ///
  /// [exception] The exception that occurred
  /// [stackTrace] Optional stack trace for debugging
  /// [reason] Optional description of what was happening when the error occurred
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
  });

  /// Logs a fatal error to Crashlytics.
  ///
  /// Use this for critical errors that cause the app to crash or become unusable.
  ///
  /// [exception] The exception that occurred
  /// [stackTrace] The stack trace for debugging
  /// [reason] Optional description of what was happening when the error occurred
  Future<void> recordFatalError(
    Object exception,
    StackTrace stackTrace, {
    String? reason,
  });

  /// Sets a custom key-value pair that will be associated with all crash reports.
  ///
  /// Useful for tracking user properties or app state.
  ///
  /// [key] The key to identify the custom value
  /// [value] The value to store (String, int, double, or bool)
  Future<void> setCustomKey(String key, Object value);

  /// Sets the user identifier for crash reports.
  ///
  /// This helps track which users are experiencing issues.
  ///
  /// [userId] The user's identifier (should be anonymized if needed)
  Future<void> setUserIdentifier(String userId);

  /// Logs a custom message to Crashlytics.
  ///
  /// Use this to add custom logging for debugging purposes.
  ///
  /// [message] The message to log
  Future<void> log(String message);

  /// Checks if crash reporting collection is enabled.
  ///
  /// Returns true if Crashlytics is actively collecting crash reports.
  Future<bool> isCrashlyticsCollectionEnabled();

  /// Enables or disables Crashlytics collection.
  ///
  /// [enabled] True to enable collection, false to disable
  Future<void> setCrashlyticsCollectionEnabled({required bool enabled});
}
