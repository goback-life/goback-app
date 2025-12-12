import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_router/src/data/providers/router_repository_provider.dart';
import 'package:dedecube_router/src/domain/use_cases/go_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'go_provider.g.dart';

/// Navigates to the given route within the application.
///
/// Creates an instance of [`GoUseCase`]
/// and executes it to perform the navigation operation.
///
/// - [ref]: The provider reference.
/// - [route]: The [BaseRoutable] route to navigate to.
/// - [context]: The build context, if any.
///
/// Returns a `Future` that completes when the navigation operation is executed.
@Riverpod(keepAlive: false)
Future<void> go(
  Ref ref,
  BaseRoutable route, {
  BuildContext? context,
}) async {
  final goUseCase = GoUseCase(
    repository: ref.watch(routerRepositoryProvider),
    route: route,
    context: context,
  );

  return await goUseCase.execute();
}
