import 'package:dedecube_logger/src/data/enums/log_severity.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Maps [LogSeverity] to [LogSeverity] for integration with Talker.
///
/// Example:
///
/// ```dart
/// TalkerLogLevel level = LogSeverity.info.toTalkerLogLevel();
/// ```
extension LogSeverityMapper on LogSeverity {
  /// Maps [LogSeverity] to [LogSeverity].
  ///
  /// Example:
  ///
  /// ```dart
  /// TalkerLogLevel talkerLevel = LogSeverity.error.toTalkerLogLevel();
  /// ```
  LogLevel toTalkerLogLevel() {
    switch (this) {
      case LogSeverity.log:
        return LogLevel.debug;
      case LogSeverity.info:
        return LogLevel.info;
      case LogSeverity.warning:
        return LogLevel.warning;
      case LogSeverity.error:
        return LogLevel.error;
      case LogSeverity.critical:
        return LogLevel.critical;
    }
  }
}
