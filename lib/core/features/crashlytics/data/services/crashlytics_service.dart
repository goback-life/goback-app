import 'package:cloudless/core/features/crashlytics/domain/contracts/crashlytics_service_contract.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService implements CrashlyticsServiceContract {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: false,
      );

      logger.warning(
        'Non-fatal error recorded to Crashlytics',
        exception: exception,
        stackTrace: stackTrace,
      );
    } catch (e, s) {
      logger.error(
        'Failed to record error to Crashlytics',
        exception: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> recordFatalError(
    Object exception,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: true,
      );

      logger.error(
        'Fatal error recorded to Crashlytics',
        exception: exception,
        stackTrace: stackTrace,
      );
    } catch (e, s) {
      logger.error(
        'Failed to record fatal error to Crashlytics',
        exception: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);

      logger.info('Custom key set in Crashlytics: $key = $value');
    } catch (e, s) {
      logger.error(
        'Failed to set custom key in Crashlytics',
        exception: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> setUserIdentifier(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);

      logger.info('User identifier set in Crashlytics: $userId');
    } catch (e, s) {
      logger.error(
        'Failed to set user identifier in Crashlytics',
        exception: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e, s) {
      logger.error(
        'Failed to log message to Crashlytics',
        exception: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<bool> isCrashlyticsCollectionEnabled() async {
    try {
      return _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e, s) {
      logger.error(
        'Failed to check Crashlytics collection status',
        exception: e,
        stackTrace: s,
      );
      return false;
    }
  }

  @override
  Future<void> setCrashlyticsCollectionEnabled({required bool enabled}) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);

      logger.info('Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e, s) {
      logger.error(
        'Failed to set Crashlytics collection status',
        exception: e,
        stackTrace: s,
      );
    }
  }
}
