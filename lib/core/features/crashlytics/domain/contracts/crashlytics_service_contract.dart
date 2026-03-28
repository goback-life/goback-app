/// Contract for Firebase Crashlytics service operations.
abstract class CrashlyticsServiceContract {
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
  });

  Future<void> recordFatalError(
    Object exception,
    StackTrace stackTrace, {
    String? reason,
  });

  Future<void> setCustomKey(String key, Object value);

  Future<void> setUserIdentifier(String userId);

  Future<void> log(String message);

  Future<bool> isCrashlyticsCollectionEnabled();

  Future<void> setCrashlyticsCollectionEnabled({required bool enabled});
}
