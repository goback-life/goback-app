import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/data/providers/router_repository_provider.dart';
import 'package:dedecube_router/src/domain/use_cases/can_pop_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'can_pop_provider.g.dart';

/// Checks whether the current route can be popped off the navigation stack.
///
/// Creates an instance of [CanPopUseCase] and executes it to perform the check operation.
///
/// Parameters:
/// - [ref]: The provider reference.
/// - [context]: The build context, if provided.
///
/// Returns a [Future<bool>] which completes with `true` if a route can be popped, or `false` otherwise.
@Riverpod(keepAlive: false)
Future<bool> canPop(
  Ref ref, {
  BuildContext? context,
}) async {
  final canPopUseCase = CanPopUseCase(
    repository: ref.watch(routerRepositoryProvider),
    context: context,
  );
  return await canPopUseCase.execute();
}
