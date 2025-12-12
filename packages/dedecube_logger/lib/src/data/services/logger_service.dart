import 'dart:developer' as developer;

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/configs/http_logger_config.dart';
import 'package:dedecube_logger/src/data/configs/logger_config.dart';
import 'package:dedecube_logger/src/data/utilities/log_severity_mapper.dart';
import 'package:dedecube_logger/src/data/utilities/route_log.dart';
import 'package:dedecube_logger/src/domain/contracts/logger_service_contract.dart';
import 'package:dedecube_logger/src/domain/typedefs/http_logger_interceptor_typedef.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LoggerService implements LoggerServiceContract {
  LoggerService(
    Ref ref, {
    required this.config,
  }) {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        enabled: config.isLogEnabled,
      ),
      logger: TalkerLogger(
        output: _defaultFlutterOutput,
        settings: TalkerLoggerSettings(
          level: config.logSeverity.toTalkerLogLevel(),
        ),
      ),
    );
  }

  static void _defaultFlutterOutput(String message) {
    if (kIsWeb) {
      // ignore: avoid_print
      print(message);
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        developer.log(message, name: 'Talker');
        break;
      default:
        debugPrint(message);
    }
  }

  final LoggerConfig config;
  late Talker _talker;

  @override
  void log(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _talker.log(
      _formatMessage(message, arguments),
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  @override
  void logInfo(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _talker.info(
      _formatMessage(message, arguments),
      exception,
      stackTrace,
    );
  }

  @override
  void logWarning(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _talker.warning(
      _formatMessage(message, arguments),
      exception,
      stackTrace,
    );
  }

  @override
  void logError(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _talker.error(
      //_formatMessage(message, arguments),
      message,
      exception,
      stackTrace,
    );
  }

  @override
  void logCritical(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _talker.critical(
      _formatMessage(message, arguments),
      exception,
      stackTrace,
    );
  }

  @override
  void logRouterAction(
      String action, String? name, Map<String, dynamic>? extraData) {
    final logMessage = [
      if (action.isNotEmpty) 'Action: $action',
      if (name != null && name.isNotEmpty) 'Route: $name',
      if (extraData != null && extraData.isNotEmpty) 'ExtraData: $extraData',
    ].join(', ');

    _talker.logCustom(RouteLog(
      message: logMessage,
    ));
  }

  @override
  HttpLoggerInterceptor createHttpLoggerInterceptor() {
    final httpLoggerConfig =
        HttpLoggerConfig(isEnabled: config.isHttpLogEnabled);

    return TalkerDioLogger(
      talker: _talker,
      settings: TalkerDioLoggerSettings(
        enabled: httpLoggerConfig.isEnabled,
        printResponseData: httpLoggerConfig.logResponseData,
        printResponseHeaders: httpLoggerConfig.logResponseHeaders,
        printResponseMessage: httpLoggerConfig.logResponseMessage,
        printResponseRedirects: httpLoggerConfig.logResponseRedirects,
        printResponseTime: httpLoggerConfig.logResponseTime,
        printErrorData: httpLoggerConfig.logErrorData,
        printErrorHeaders: httpLoggerConfig.logErrorHeaders,
        printErrorMessage: httpLoggerConfig.logErrorMessage,
        printRequestData: httpLoggerConfig.logRequestData,
        printRequestHeaders: httpLoggerConfig.logRequestHeaders,
      ),
    );
  }

  String _formatMessage(String message, Map<String, dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return message;
    }

    final argsString =
        arguments.entries.map((e) => '    ${e.key}: ${e.value}').join('\n');

    return '$message\nArguments:\n$argsString';
  }
}
