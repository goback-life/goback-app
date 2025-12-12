import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/domain/contracts/router_repository_contract.dart';
import 'package:flutter/widgets.dart' as widgets;

/// [CanPopUseCase] handles checking whether the current route can be popped off the navigation stack.
///
/// Implements the [`UseCaseContract<bool>`] to execute the check operation.
///
/// - [repository]: An instance of [`RouterRepositoryContract`] used to perform navigation operations.
/// - [context]: The optional build context, if required.
///
/// When executed, this use case delegates the check operation to the [repository]'s
/// [`canPop`] method.
class CanPopUseCase implements UseCaseContract<bool> {
  /// Creates an instance of [CanPopUseCase] with the required dependencies.
  CanPopUseCase({
    required this.repository,
    this.context,
  });

  /// The repository responsible for handling routing operations.
  final RouterRepositoryContract repository;

  /// The optional build context, if required.
  final widgets.BuildContext? context;

  /// Executes the use case to check if there is a route that can be popped.
  @override
  Future<bool> execute() {
    return repository.canPop(
      context: context,
    );
  }
}
