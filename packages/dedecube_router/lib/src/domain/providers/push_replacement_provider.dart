import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_router/src/data/providers/router_repository_provider.dart';
import 'package:dedecube_router/src/domain/use_cases/push_replacement_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_replacement_provider.g.dart';

/// Pushes a given [BaseRoutable] route onto the navigation stack by replacing
/// the current route.
///
/// Creates an instance of [`PushReplacementUseCase`]
/// and executes it to perform the navigation operation.
///
/// - [ref]: The provider reference.
/// - [route]: The [BaseRoutable] route to be pushed.
/// - [context]: The build context, if any.
///
/// Returns a `Future` that completes when the push replacement operation is executed.
@Riverpod(keepAlive: false)
Future<void> pushReplacement(
  Ref ref,
  BaseRoutable route, {
  BuildContext? context,
}) async {
  final pushReplacementUseCase = PushReplacementUseCase(
    repository: ref.watch(routerRepositoryProvider),
    route: route,
    context: context,
  );

  return await pushReplacementUseCase.execute();
}
