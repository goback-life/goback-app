import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.dart';
import 'package:cloudless/presentation/pages/time_limit_reached/time_limit_reached_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/widgets.dart';

/// Middleware that blocks navigation if time limit is reached
class TimeLimitMiddleware extends Middleware {
  TimeLimitMiddleware._();

  factory TimeLimitMiddleware() {
    return _instance ??= TimeLimitMiddleware._();
  }

  static TimeLimitMiddleware? _instance;

  @override
  List<Routable> get excludedRoutes => [const TimeLimitReachedRoutable()];

  @override
  Future<Routable?> handle(
    BuildContext context,
    CustomRouterState state,
  ) async {
    try {
      final container = riverpodContainer();

      // Check current time limit state
      final timeLimitState = await container.read(
        timeLimitTrackerNotifierProvider.future,
      );

      // If limit is reached, redirect to block screen
      if (timeLimitState.isLimitReached) {
        logger.info(
          'Time limit reached - redirecting to block screen from middleware',
        );
        return const TimeLimitReachedRoutable();
      }
    } catch (e, stackTrace) {
      logger.error(
        'Error checking time limit in middleware',
        exception: e,
        stackTrace: stackTrace,
      );
    }

    // Allow navigation if limit not reached
    return null;
  }
}
