import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/domain/contracts/router_repository_contract.dart';
import 'package:flutter/widgets.dart' as widgets;

/// [PopUseCase] handles popping the current route off the navigation stack.
///
/// Implements the [`UseCaseContract<void>`] to execute the pop operation.
///
/// - [repository]: An instance of [`RouterRepositoryContract`] used to perform navigation operations.
/// - [context]: The optional build context, if required.
///
/// When executed, this use case delegates the pop operation to the [repository]'s
/// [`pop`] method.
class PopUseCase implements UseCaseContract<void> {
  /// Creates an instance of [PopUseCase] with the required dependencies.
  PopUseCase({
    required this.repository,
    this.context,
  });

  /// The repository responsible for handling routing operations.
  final RouterRepositoryContract repository;

  /// The optional build context, if required.
  final widgets.BuildContext? context;

  /// Executes the use case to pop the current route off the navigation stack.
  @override
  Future<void> execute() {
    return repository.pop(
      context: context,
    );
  }
}
