import 'dart:math';

/// Calculates the goback score (0-100) based on battery drain, charging state,
/// and step count.
///
/// Battery drain is the primary signal when reliable (no charging detected).
/// Steps provide a one-way boost — high steps = corroboration of disconnection,
/// but 0 steps is neutral (meditation, reading, napping are valid).
/// Charging degrades battery signal confidence, shifting weight to steps.
class GobackScoreCalculator {
  const GobackScoreCalculator._();

  /// Returns null only if duration is too short (<= 60s).
  ///
  /// When battery data is unavailable, falls back to a time-only score
  /// (0.7 base) boosted by steps if available.
  static int? calculate({
    required int? batteryStart,
    required int? batteryEnd,
    required Duration duration,
    int? steps,
    bool wasCharging = false,
  }) {
    if (duration.inSeconds <= 60) {
      return null;
    }

    final durationMinutes = duration.inMinutes.toDouble();
    final durationHours = duration.inSeconds / 3600.0;

    // Time multiplier: 0.7 at 0 min → 1.0 at 4 hrs
    final timeMultiplier =
        0.7 + 0.3 * (durationMinutes / 240.0).clamp(0.0, 1.0);

    // Step bonus: 0.0 (no data / 0 steps) → 0.3 (≥3000 steps/hr)
    final stepBonus = steps != null && steps > 0
        ? 0.3 * ((steps / durationHours) / 3000.0).clamp(0.0, 1.0)
        : 0.0;

    double quality;

    if (batteryStart != null && batteryEnd != null && !wasCharging) {
      // Case 1: battery reliable, steps are a bonus
      final drain = max(0, batteryStart - batteryEnd);
      final drainPerHour = drain / durationHours;
      final batteryQuality = (1.0 - (drainPerHour - 2.0) / 13.0).clamp(
        0.0,
        1.0,
      );
      quality = (batteryQuality + stepBonus).clamp(0.0, 1.0);
    } else if (batteryStart != null && batteryEnd != null && wasCharging) {
      // Case 2: battery unreliable due to charging
      if (stepBonus > 0) {
        // Steps rescue the score
        quality = (0.7 + stepBonus).clamp(0.0, 1.0);
      } else {
        // No steps — use battery but cap at 0.7
        final drain = max(0, batteryStart - batteryEnd);
        final drainPerHour = drain / durationHours;
        final batteryQuality = (1.0 - (drainPerHour - 2.0) / 13.0).clamp(
          0.0,
          1.0,
        );
        quality = batteryQuality.clamp(0.0, 0.7);
      }
    } else {
      // Case 3: no battery data — fallback + step bonus
      quality = (0.7 + stepBonus).clamp(0.0, 1.0);
    }

    return (quality * 100.0 * timeMultiplier).round().clamp(0, 100);
  }
}
