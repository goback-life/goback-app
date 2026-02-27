import 'dart:math';

/// Calculates the goback score (0-100) based on battery drain and lockout duration.
///
/// Less battery drain = phone was down = higher quality lockout.
/// Longer lockouts earn a small time bonus.
class GobackScoreCalculator {
  const GobackScoreCalculator._();

  /// Returns null if battery data is unavailable or duration <= 0.
  static int? calculate({
    required int? batteryStart,
    required int? batteryEnd,
    required Duration duration,
  }) {
    if (batteryStart == null || batteryEnd == null) return null;
    if (duration.inSeconds <= 60) return null; // < 1 min

    final durationHours = duration.inSeconds / 3600.0;
    final durationMinutes = duration.inMinutes.toDouble();

    // Negative drain = charging, treat as 0
    final batteryDrain = max(0, batteryStart - batteryEnd);
    final drainPerHour = batteryDrain / durationHours;

    // 2%/hr (idle) = 1.0 perfect, 15%/hr (heavy use) = 0.0
    final batteryQuality = (1.0 - (drainPerHour - 2.0) / 13.0).clamp(0.0, 1.0);

    // 0 min = 0.7x, 240 min (4hr) = 1.0x
    final timeMultiplier =
        0.7 + 0.3 * (durationMinutes / 240.0).clamp(0.0, 1.0);

    return (batteryQuality * 100.0 * timeMultiplier).round();
  }
}
