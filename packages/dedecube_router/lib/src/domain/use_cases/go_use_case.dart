import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/domain/contracts/router_repository_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

/// [GoUseCase] handles navigating to a specified route within the application.
///
/// Implements the [`UseCaseContract<void>`] to execute the navigation operation.
///
/// - [repository]: An instance of [`RouterRepositoryContract`] used to perform navigation operations.
/// - [route]: The [BaseRoutable] route to navigate to.
/// - [context]: The optional build context, if required.
///
/// When executed, this use case delegates the navigation task to the [repository]'s
/// [`go`] method.
class GoUseCase implements UseCaseContract<void> {
  /// Creates an instance of [GoUseCase] with the required dependencies.
  GoUseCase({
    required this.repository,
    required this.route,
    this.context,
  });

  /// The repository responsible for handling routing operations.
  final RouterRepositoryContract repository;

  /// The [BaseRoutable] route to navigate to.
  final BaseRoutable route;

  /// The optional build context, if required.
  final widgets.BuildContext? context;

  /// Executes the use case to perform navigation to the specified route.
  @override
  Future<void> execute() {
    return repository.go(
      route,
      context: context,
    );
  }
}
