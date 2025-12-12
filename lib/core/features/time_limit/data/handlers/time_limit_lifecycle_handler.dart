import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/widgets.dart';

/// Handles app lifecycle events for time limit tracking
/// Pauses tracking when app goes to background, resumes when app returns to foreground
/// Checks for new day on resume and resets usage if needed
class TimeLimitLifecycleHandler with WidgetsBindingObserver {
  TimeLimitLifecycleHandler(this.ref) {
    initialize();
  }

  final WidgetRef ref;

  /// Initialize time limit tracking on app start
  Future<void> initialize() async {
    try {
      // Load initial time limit state
      final timeLimitState = await ref.read(
        timeLimitTrackerNotifierProvider.future,
      );

      logger.info(
        'Time limit initialized: ${timeLimitState.usedMinutes}/${timeLimitState.minutes} minutes',
      );

      // Note: Navigation is handled by TimeLimitMiddleware
      // No need to navigate here as middleware will catch any navigation attempt
    } catch (e, stackTrace) {
      logger.error(
        'Error initializing time limit tracking',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being terminated or hidden
        _onAppPaused();
        break;
    }
  }

  Future<void> _onAppResumed() async {
    logger.info('App resumed - checking time limit status');

    try {
      final notifier = ref.read(timeLimitTrackerNotifierProvider.notifier);

      // Check if it's a new day and reset if needed
      await notifier.checkAndResetIfNewDay();

      // Get current state and resume tracking if needed
      ref.read(timeLimitTrackerNotifierProvider).whenData((timeLimit) {
        if (!timeLimit.isLimitReached) {
          // Resume tracking if limit not reached
          notifier.startTracking();
          logger.info('Time limit tracking resumed');
        } else {
          logger.info('Time limit already reached - staying on block screen');
        }
      });
    } catch (e, stackTrace) {
      logger.error(
        'Error handling app resume for time limit',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _onAppPaused() {
    logger.info('App paused - stopping time limit tracking');

    try {
      ref.read(timeLimitTrackerNotifierProvider.notifier).stopTracking();
    } catch (e, stackTrace) {
      logger.error(
        'Error handling app pause for time limit',
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }
}
