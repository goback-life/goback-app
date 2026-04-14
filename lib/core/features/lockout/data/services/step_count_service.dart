import 'dart:async';

import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:pedometer/pedometer.dart';

/// Tracks step count during a lockout session.
///
/// Subscribes to the device pedometer at lockout start and accumulates steps.
/// On iOS, CMPedometer buffers steps while the app is suspended and delivers
/// them when the app resumes — no background task needed.
///
/// If motion permission is denied, [getStepsSinceStart] returns null and
/// the score calculator treats this as neutral (no penalty).
class StepCountService {
  StreamSubscription<StepCount>? _subscription;
  int? _baselineSteps;
  int? _latestSteps;

  /// Begins tracking steps. Call at lockout start.
  void startTracking() {
    _baselineSteps = null;
    _latestSteps = null;
    _subscription?.cancel();

    _subscription = Pedometer.stepCountStream.listen(
      (event) {
        _baselineSteps ??= event.steps;
        _latestSteps = event.steps;
      },
      onError: (error) {
        // Permission denied or sensor unavailable — silent fallback
        logger.warning(
          'Pedometer error (permission denied?)',
          exception: error,
        );
        _subscription?.cancel();
        _subscription = null;
      },
    );
  }

  /// Returns steps accumulated since [startTracking] was called.
  /// Returns null if tracking was never started, permission was denied,
  /// or no step events were received.
  int? getStepsSinceStart() {
    if (_baselineSteps == null || _latestSteps == null) {
      return null;
    }
    return _latestSteps! - _baselineSteps!;
  }

  /// Stops tracking and cleans up the subscription.
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _baselineSteps = null;
    _latestSteps = null;
  }
}
