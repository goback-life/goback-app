import 'package:dedecube_logger/src/data/services/logger_service.dart';
import 'package:dedecube_logger/src/domain/contracts/logger_repository_contract.dart';

class LoggerRepository implements LoggerRepositoryContract {
  const LoggerRepository({required this.loggerService});

  final LoggerService loggerService;

  @override
  void log(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    loggerService.log(
      message,
      arguments: arguments,
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
    loggerService.logInfo(
      message,
      arguments: arguments,
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  @override
  void logWarning(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    loggerService.logWarning(
      message,
      arguments: arguments,
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  @override
  void logError(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    loggerService.logError(
      message,
      arguments: arguments,
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  @override
  void logCritical(
    String message, {
    Map<String, dynamic>? arguments,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    loggerService.logCritical(
      message,
      arguments: arguments,
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  @override
  void logRouterAction(
      String action, String? name, Map<String, dynamic>? extraData) {
    loggerService.logRouterAction(
      action,
      name,
      extraData,
    );
  }
}
