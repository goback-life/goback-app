import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/domain/contracts/router_repository_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

/// [ReplaceUseCase] handles replacing the current route with the given [BaseRoutable] route.
///
/// Implements the [`UseCaseContract<void>`] to execute the replace operation.
///
/// - [repository]: An instance of [`RouterRepositoryContract`] used to perform navigation operations.
/// - [route]: The [BaseRoutable] route to replace the current route.
/// - [context]: The optional build context, if required.
///
/// When executed, this use case delegates the navigation task to the [repository]'s
/// [`replace`] method.
class ReplaceUseCase implements UseCaseContract<void> {
  /// Creates an instance of [ReplaceUseCase] with the required dependencies.
  ReplaceUseCase({
    required this.repository,
    required this.route,
    this.context,
  });

  /// The repository responsible for handling navigation operations.
  final RouterRepositoryContract repository;

  /// The [BaseRoutable] route to replace the current route.
  final BaseRoutable route;

  /// The optional build context, if required.
  final widgets.BuildContext? context;

  /// Executes the use case to replace the current route.
  @override
  Future<void> execute() {
    return repository.replace(
      route,
      context: context,
    );
  }
}
