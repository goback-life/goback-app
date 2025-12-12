import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/data/providers/logger_repository_provider.dart';
import 'package:dedecube_logger/src/domain/use_cases/log_info_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_info_provider.g.dart';

/// Logs an informational message.
///
/// Creates a [`LogInfoUseCase`](lib/src/domain/use_cases/log_info_use_case.dart) instance and executes it.
///
/// - [ref]: The provider reference.
/// - [message]: The informational message to log.
/// - [arguments]: Additional contextual information.
/// - [exception]: An exception to log.
/// - [stackTrace]: The stack trace associated with the exception.
@Riverpod(keepAlive: false)
void logInfo(
  Ref ref,
  String message, {
  Map<String, dynamic>? arguments,
  Object? exception,
  StackTrace? stackTrace,
}) {
  final logUseCase = LogInfoUseCase(
    repository: ref.watch(loggerRepositoryProvider),
    message: message,
    arguments: arguments,
    exception: exception,
    stackTrace: stackTrace,
  );

  return logUseCase.execute();
}
