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
  }) => _guard('record error', () async {
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
  });

  @override
  Future<void> recordFatalError(
    Object exception,
    StackTrace stackTrace, {
    String? reason,
  }) => _guard('record fatal error', () async {
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
  });

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _guard('set custom key', () async {
        await _crashlytics.setCustomKey(key, value);
        logger.info('Custom key set in Crashlytics: $key = $value');
      });

  @override
  Future<void> setUserIdentifier(String userId) =>
      _guard('set user identifier', () async {
        await _crashlytics.setUserIdentifier(userId);
        logger.info('User identifier set in Crashlytics: $userId');
      });

  @override
  Future<void> log(String message) =>
      _guard('log message', () => _crashlytics.log(message));

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
  Future<void> setCrashlyticsCollectionEnabled({required bool enabled}) =>
      _guard('set Crashlytics collection status', () async {
        await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
        logger.info(
          'Crashlytics collection ${enabled ? 'enabled' : 'disabled'}',
        );
      });

  Future<void> _guard(String operation, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, s) {
      logger.error(
        'Failed to $operation in Crashlytics',
        exception: e,
        stackTrace: s,
      );
    }
  }
}
