import 'dart:async';

import 'package:cloudless/core/features/crashlytics/data/providers/crashlytics_service_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Utility service for initializing Firebase Crashlytics during app startup.
///
/// This service handles:
/// - Firebase initialization
/// - Crashlytics setup
/// - Global error handler configuration for Flutter and Dart errors
class CrashlyticsStartupService {
  /// Initializes Firebase and Crashlytics, and sets up error handlers.
  ///
  /// This method should be called during app startup. It safely handles
  /// Firebase initialization even if it has already been initialized by
  /// another Firebase service.
  ///
  /// Note: Crashlytics is automatically disabled in debug mode to avoid
  /// polluting crash reports with development errors.
  static Future<void> initialize(WidgetRef ref) async {
    try {
      // Don't initialize Crashlytics in debug mode
      if (kDebugMode) {
        logger.info('Crashlytics disabled in debug mode');
        return;
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        logger.info('Firebase initialized successfully');
      } else {
        logger.info('Firebase already initialized, skipping initialization');
      }

      // Get the crashlytics service
      final crashlyticsService = ref.read(crashlyticsServiceProvider);

      // Set up Flutter error handlers
      _setupFlutterErrorHandling(crashlyticsService);

      // Set up Dart error handlers
      _setupDartErrorHandling(crashlyticsService);

      logger.info('Crashlytics initialized successfully');
    } catch (e, s) {
      logger.error(
        'Failed to initialize Crashlytics',
        exception: e,
        stackTrace: s,
      );
      // Don't rethrow - allow the app to continue even if Crashlytics fails
    }
  }

  /// Sets up Flutter framework error handlers.
  ///
  /// Configures FlutterError.onError to report errors to Crashlytics
  /// while preserving the original error handler behavior.
  static void _setupFlutterErrorHandling(dynamic crashlyticsService) {
    // Store the original error handler
    final originalFlutterErrorOnError = FlutterError.onError;

    // Override with our custom handler
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);

      // Call original handler if it exists
      if (originalFlutterErrorOnError != null) {
        originalFlutterErrorOnError(details);
      }
    };

    logger.info('Flutter error handling configured');
  }

  /// Sets up Dart error handlers for uncaught async errors.
  ///
  /// Configures PlatformDispatcher.onError to report errors to Crashlytics
  /// while preserving the original error handler behavior.
  static void _setupDartErrorHandling(dynamic crashlyticsService) {
    // Store the original error handler
    final originalPlatformDispatcherOnError =
        PlatformDispatcher.instance.onError;

    // Override with our custom handler
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);

      // Call original handler if it exists, otherwise return true
      if (originalPlatformDispatcherOnError != null) {
        return originalPlatformDispatcherOnError(error, stackTrace);
      }

      return true;
    };

    logger.info('Dart error handling configured');
  }
}
