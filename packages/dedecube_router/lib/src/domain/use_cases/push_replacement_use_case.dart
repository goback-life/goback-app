import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/domain/contracts/router_repository_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

/// [PushReplacementUseCase] handles pushing a given [BaseRoutable] route onto the navigation stack by replacing the current route.
///
/// Implements the [`UseCaseContract<void>`] to execute the push replacement operation.
///
/// - [repository]: An instance of [`RouterRepositoryContract`] used to perform navigation operations.
/// - [route]: The [BaseRoutable] route to be pushed as a replacement.
/// - [context]: The optional build context, if required.
///
/// When executed, this use case delegates the navigation task to the [repository]'s
/// [`pushReplacement`] method.
class PushReplacementUseCase implements UseCaseContract<void> {
  /// Creates an instance of [PushReplacementUseCase] with the required dependencies.
  PushReplacementUseCase({
    required this.repository,
    required this.route,
    this.context,
  });

  /// The repository responsible for handling navigation operations.
  final RouterRepositoryContract repository;

  /// The [BaseRoutable] route to be pushed as a replacement.
  final BaseRoutable route;

  /// The optional build context, if required.
  final widgets.BuildContext? context;

  /// Executes the use case to push the specified route as a replacement.
  @override
  Future<void> execute() {
    return repository.pushReplacement(
      route,
      context: context,
    );
  }
}
