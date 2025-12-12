import 'package:dedecube_logger/src/domain/contracts/http_logger_config_contract.dart';

class HttpLoggerConfig implements HttpLoggerConfigContract {
  const HttpLoggerConfig({
    this.isEnabled = true,
    this.logRequestData = true,
    this.logRequestHeaders = false,
    this.logResponseData = true,
    this.logResponseHeaders = false,
    this.logResponseMessage = true,
    this.logResponseRedirects = false,
    this.logResponseTime = false,
    this.logErrorData = true,
    this.logErrorHeaders = true,
    this.logErrorMessage = true,
  });

  @override
  final bool isEnabled;

  @override
  final bool logRequestData;

  @override
  final bool logRequestHeaders;

  @override
  final bool logResponseData;

  @override
  final bool logResponseHeaders;

  @override
  final bool logResponseMessage;

  @override
  final bool logResponseRedirects;

  @override
  final bool logResponseTime;

  @override
  final bool logErrorData;

  @override
  final bool logErrorHeaders;

  @override
  final bool logErrorMessage;
}
