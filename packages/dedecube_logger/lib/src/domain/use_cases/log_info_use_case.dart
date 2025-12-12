import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/domain/contracts/logger_repository_contract.dart';

/// [LogInfoUseCase] handles logging of informational messages.
///

class LogInfoUseCase implements UseCaseContract<void> {
  /// Creates a [LogInfoUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`LoggerRepositoryContract`](lib/src/domain/contracts/logger_repository_contract.dart) used to perform the logging.
  /// - [message]: The informational message to log.
  /// - [arguments]: Additional contextual information.
  /// - [exception]: An exception to log.
  /// - [stackTrace]: The stack trace associated with the exception.
  LogInfoUseCase({
    required this.repository,
    required this.message,
    this.arguments,
    this.exception,
    this.stackTrace,
  });

  /// The repository responsible for logging operations.
  final LoggerRepositoryContract repository;

  /// The informational message to be logged.
  final String message;

  /// Additional contextual information for the log.
  Map<String, dynamic>? arguments;

  /// An exception to be logged.
  Object? exception;

  /// The stack trace associated with the exception.
  StackTrace? stackTrace;

  /// Executes the use case to log an informational message.
  ///
  /// Delegates the logging task to the [repository]'s [`logInfo`](lib/src/domain/contracts/logger_repository_contract.dart) method.
  @override
  void execute() {
    repository.logInfo(
      message,
      arguments: arguments,
      exception: exception,
      stackTrace: stackTrace,
    );
  }
}
