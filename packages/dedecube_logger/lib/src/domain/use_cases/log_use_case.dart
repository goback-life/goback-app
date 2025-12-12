import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/domain/contracts/logger_repository_contract.dart';

/// [LogUseCase] handles logging of general messages.
///

class LogUseCase implements UseCaseContract<void> {
  /// Creates a [LogUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`LoggerRepositoryContract`](lib/src/domain/contracts/logger_repository_contract.dart) used to perform the logging.
  /// - [message]: The message to log.
  /// - [arguments]: Additional contextual information.
  /// - [exception]: An exception to log.
  /// - [stackTrace]: The stack trace associated with the exception.
  LogUseCase({
    required this.repository,
    required this.message,
    this.arguments,
    this.exception,
    this.stackTrace,
  });

  /// The repository responsible for logging operations.
  final LoggerRepositoryContract repository;

  /// The message to be logged.
  final String message;

  /// Additional contextual information for the log.
  final Map<String, dynamic>? arguments;

  /// An exception to be logged.
  final Object? exception;

  /// The stack trace associated with the exception.
  final StackTrace? stackTrace;

  /// Executes the use case to log a message.
  ///
  /// Delegates the logging task to the [repository]'s [`log`](lib/src/domain/contracts/logger_repository_contract.dart) method.
  @override
  void execute() {
    repository.log(
      message,
      arguments: arguments,
      exception: exception,
      stackTrace: stackTrace,
    );
  }
}
