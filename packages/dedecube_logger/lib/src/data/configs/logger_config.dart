import 'package:dedecube_logger/src/data/enums/log_severity.dart';
import 'package:dedecube_logger/src/domain/contracts/logger_config_contract.dart';

class LoggerConfig implements LoggerConfigContract {
  LoggerConfig({
    String? logSeverity,
    bool? isHttpLogEnabled,
  })  : logSeverity = LogSeverity.fromString(logSeverity),
        isLogEnabled = logSeverity != null,
        isHttpLogEnabled =
            _resolveSubLoggerEnabled(logSeverity, isHttpLogEnabled);

  @override
  final LogSeverity logSeverity;

  @override
  final bool isLogEnabled;

  @override
  final bool isHttpLogEnabled;

  static bool _resolveSubLoggerEnabled(
      String? logSeverity, bool? subLoggerEnabled) {
    if (logSeverity == null) {
      return false;
    }

    return subLoggerEnabled ?? false;
  }
}
