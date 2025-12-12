import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_logger/src/domain/contracts/logger_repository_contract.dart';

/// [LogRouterActionUseCase] handles logging of router navigation actions.
///
/// This use case captures and logs navigation events within the application,
/// including the action type, route name, and any additional data associated
/// with the navigation event.
class LogRouterActionUseCase implements UseCaseContract<void> {
  /// Creates a [LogRouterActionUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`LoggerRepositoryContract`](lib/src/domain/contracts/logger_repository_contract.dart) used to perform the logging.
  /// - [action]: The navigation action type (e.g., "push", "pop", "replace").
  /// - [name]: The name of the route being navigated to or from.
  /// - [extraData]: Additional contextual information about the navigation.
  LogRouterActionUseCase({
    required this.repository,
    required this.action,
    required this.name,
    required this.extraData,
  });

  /// The repository responsible for logging operations.
  final LoggerRepositoryContract repository;

  /// The navigation action type (e.g., "push", "pop", "replace").
  final String action;

  /// The name of the route being navigated to or from.
  final String? name;

  /// Additional contextual information about the navigation.
  final Map<String, dynamic>? extraData;

  /// Executes the use case to log a router navigation action.
  ///
  /// Delegates the logging task to the [repository]'s [`logRouterAction`](lib/src/domain/contracts/logger_repository_contract.dart) method.
  @override
  void execute() {
    repository.logRouterAction(
      action,
      name,
      extraData,
    );
  }
}
