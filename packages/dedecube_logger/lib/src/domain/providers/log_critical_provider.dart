import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/providers/logger_repository_provider.dart';
import 'package:dedecube_logger/src/domain/use_cases/log_critical_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_critical_provider.g.dart';

/// Logs a critical message.
///
/// Creates a [`LogCriticalUseCase`](lib/src/domain/use_cases/log_critical_use_case.dart) instance and executes it.
///
/// - [ref]: The provider reference.
/// - [message]: The critical message to log.
/// - [arguments]: Additional contextual information.
/// - [exception]: An exception to log.
/// - [stackTrace]: The stack trace associated with the exception.
@Riverpod(keepAlive: false)
void logCritical(
  Ref ref,
  String message, {
  Map<String, dynamic>? arguments,
  Object? exception,
  StackTrace? stackTrace,
}) {
  final logUseCase = LogCriticalUseCase(
    repository: ref.watch(loggerRepositoryProvider),
    message: message,
    arguments: arguments,
    exception: exception,
    stackTrace: stackTrace,
  );

  return logUseCase.execute();
}
