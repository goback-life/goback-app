import 'package:dedecube_environment/dedecube_environment.dart';
import 'package:dedecube_logger/dedecube_logger.dart';

/// The [LoggerConfig] includes an [HttpLoggerConfig] for HTTP-specific logging settings.
/// Configuration for the logger service.
///
/// This getter provides a [LoggerConfig] instance with settings loaded from environment variables:
/// * LOG_SEVERITY: The severity level of logging
/// * APP_DEBUG_HTTP_DIAGNOSTICS: Enables or disables HTTP diagnostics logging
LoggerConfig get loggerConfig {
  final loggerConfig = LoggerConfig(
    logSeverity: environment.tryGetString('LOG_SEVERITY'),
    isHttpLogEnabled:
        environment.tryGetBool('APP_DEBUG_HTTP_DIAGNOSTICS') ?? false,
  );
  return loggerConfig;
}
