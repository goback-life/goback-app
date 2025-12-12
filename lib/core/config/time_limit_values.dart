import 'package:dedecube_startup/dedecube_startup.dart';

/// Configuration for time limit values.
/// Values are read from environment variables with defaults.
class TimeLimitValues {
  /// Short time limit in minutes (default: 5)
  static int getShortMinutes() {
    return environment.getInt('TIME_LIMIT_SHORT', 5);
  }

  /// Long time limit in minutes (default: 21)
  static int getLongMinutes() {
    return environment.getInt('TIME_LIMIT_LONG', 21);
  }

  /// Default time limit in minutes (short)
  static int getDefaultMinutes() => getShortMinutes();
}
