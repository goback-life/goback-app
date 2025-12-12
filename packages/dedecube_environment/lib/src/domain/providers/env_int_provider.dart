import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/data/providers/environment_repository_provider.dart';
import 'package:dedecube_environment/src/domain/use_cases/env_int_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_int_provider.g.dart';

/// Retrieves an integer environment variable.
///
/// Creates an instance of [`EnvIntUseCase`](lib/src/domain/use_cases/env_int_use_case.dart)
/// and executes it to obtain the environment variable.
///
/// - [ref]: The provider reference.
/// - [key]: The environment variable key.
/// - [defaultValue]: The default value if the key is not found.
///
/// Returns the integer value associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
int? envInt(
  Ref ref,
  String key, {
  int? defaultValue,
}) {
  final envUseCase = EnvIntUseCase(
    repository: ref.watch(environmentRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return envUseCase.execute();
}
