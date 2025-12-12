import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_router/src/data/providers/router_repository_provider.dart';
import 'package:dedecube_router/src/domain/use_cases/replace_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replace_provider.g.dart';

/// Replaces the current route with the given [BaseRoutable] route.
///
/// Creates an instance of [`ReplaceUseCase`]
/// and executes it to perform the replacement operation.
///
/// - [ref]: The provider reference.
/// - [route]: The [BaseRoutable] route to replace the current route.
/// - [context]: The build context, if any.
///
/// Returns a `Future` that completes when the replacement operation is executed.
@Riverpod(keepAlive: false)
Future<void> replace(
  Ref ref,
  BaseRoutable route, {
  BuildContext? context,
}) async {
  final replaceUseCase = ReplaceUseCase(
    repository: ref.watch(routerRepositoryProvider),
    route: route,
    context: context,
  );

  return await replaceUseCase.execute();
}
