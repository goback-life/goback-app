import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/data/providers/environment_repository_provider.dart';
import 'package:dedecube_environment/src/domain/use_cases/env_bool_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_bool_provider.g.dart';

/// Retrieves a boolean environment variable.
///
/// Creates an instance of [`EnvBoolUseCase`](lib/src/domain/use_cases/env_bool_use_case.dart)
/// and executes it to obtain the environment variable.
///
/// - [ref]: The provider reference.
/// - [key]: The environment variable key.
/// - [defaultValue]: The default value if the key is not found.
///
/// Returns the boolean value associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
bool? envBool(
  Ref ref,
  String key, {
  bool? defaultValue,
}) {
  final envUseCase = EnvBoolUseCase(
    repository: ref.watch(environmentRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return envUseCase.execute();
}
