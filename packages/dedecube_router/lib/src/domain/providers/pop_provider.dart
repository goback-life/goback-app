import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/data/providers/router_repository_provider.dart';
import 'package:dedecube_router/src/domain/use_cases/pop_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pop_provider.g.dart';

/// Pops the current route off the navigation stack.
///
/// Creates an instance of [`PopUseCase`]
/// and executes it to perform the pop operation.
///
/// - [ref]: The provider reference.
/// - [context]: The build context, if any.
///
/// Returns a `Future` that completes when the pop operation is executed.
@Riverpod(keepAlive: false)
Future<void> pop(
  Ref ref, {
  BuildContext? context,
}) async {
  final popUseCase = PopUseCase(
    repository: ref.watch(routerRepositoryProvider),
    context: context,
  );

  return await popUseCase.execute();
}
