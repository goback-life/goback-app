import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/domain/contracts/router_repository_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

/// [PushUseCase] handles pushing a given [BaseRoutable] route onto the navigation stack.
///
/// Implements the [`UseCaseContract<void>`] to execute the push operation.
///
/// - [repository]: An instance of [`RouterRepositoryContract`] used to perform navigation operations.
/// - [route]: The [BaseRoutable] route to be pushed onto the navigation stack.
/// - [context]: The optional build context, if required.
///
/// When executed, this use case delegates the navigation task to the [repository]'s
/// [`push`] method.
class PushUseCase implements UseCaseContract<void> {
  /// Creates an instance of [PushUseCase] with the required dependencies.
  PushUseCase({
    required this.repository,
    required this.route,
    this.context,
  });

  /// The repository responsible for handling routing operations.
  final RouterRepositoryContract repository;

  /// The [BaseRoutable] route to be pushed onto the navigation stack.
  final BaseRoutable route;

  /// The optional build context, if required.
  final widgets.BuildContext? context;

  /// Executes the use case to push the specified route onto the navigation stack.
  @override
  Future<void> execute() {
    return repository.push(
      route,
      context: context,
    );
  }
}
