import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase Crashlytics and global error handlers during startup.
/// Disabled in debug mode. Non-fatal if initialization fails.
class CrashlyticsStartupService {
  static Future<void> initialize(WidgetRef ref) async {
    try {
      if (kDebugMode) {
        logger.info('Crashlytics disabled in debug mode');
        return;
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        logger.info('Firebase initialized successfully');
      }

      _setupFlutterErrorHandling();
      _setupDartErrorHandling();

      logger.info('Crashlytics initialized successfully');
    } catch (e, s) {
      logger.error(
        'Failed to initialize Crashlytics',
        exception: e,
        stackTrace: s,
      );
    }
  }

  static void _setupFlutterErrorHandling() {
    final original = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      original?.call(details);
    };
  }

  static void _setupDartErrorHandling() {
    final original = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      return original?.call(error, stackTrace) ?? true;
    };
  }
}
