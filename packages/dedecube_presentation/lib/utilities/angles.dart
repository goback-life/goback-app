import 'dart:math' as math;

/// Extensions for angle calculations and conversions.
extension AnglesExtension on num {
  /// Normalizes an angle in radians to be within [0, 2π]
  // ignore: unused_element
  double get normalizeRadians => this % (2 * math.pi);

  /// Normalizes an angle in degrees to be within [0, 360]
  double get normalizeDegrees => this % (360);

  /// Converts radians to degrees
  double get radToDeg => this * 180 / math.pi;
  // ignore: unused_element
  double get degToRad => this * math.pi / 180;

  // ignore: unused_element
  double get quarterTurnsToDegrees => this * 90;
  // ignore: unused_element
  double get quarterTurnsToRadians => this * math.pi / 2;

  /// Calculates the clockwise angle from this angle to another angle in degrees
  double clockwiseTo(num other) => (this - other).normalizeDegrees;
  // ignore: unused_element
  bool closerClockwise(num other) => clockwiseTo(other) < 360 / 2;

  /// Calculates the shortest angular distance to another angle
  double closerAngleDistanceTo(num other) {
    final n = clockwiseTo(other);
    if (n > 180) {
      return 360 - n;
    }
    return n;
  }
}
