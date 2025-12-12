import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/providers/logger_repository_provider.dart';
import 'package:dedecube_logger/src/domain/use_cases/log_warning_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_warning_provider.g.dart';

/// Logs a warning message.
///
/// Creates a [`LogWarningUseCase`](lib/src/domain/use_cases/log_warning_use_case.dart) instance and executes it.
///
/// - [ref]: The provider reference.
/// - [message]: The warning message to log.
/// - [arguments]: Additional contextual information.
/// - [exception]: An exception to log.
/// - [stackTrace]: The stack trace associated with the exception.
@Riverpod(keepAlive: false)
void logWarning(
  Ref ref,
  String message, {
  Map<String, dynamic>? arguments,
  Object? exception,
  StackTrace? stackTrace,
}) {
  final logUseCase = LogWarningUseCase(
    repository: ref.watch(loggerRepositoryProvider),
    message: message,
    arguments: arguments,
    exception: exception,
    stackTrace: stackTrace,
  );

  return logUseCase.execute();
}
