import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/data/providers/environment_repository_provider.dart';
import 'package:dedecube_environment/src/domain/use_cases/env_string_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_string_provider.g.dart';

/// Retrieves a string environment variable.
///
/// Creates an instance of [`EnvStringUseCase`](lib/src/domain/use_cases/env_string_use_case.dart)
/// and executes it to obtain the environment variable.
///
/// - [ref]: The provider reference.
/// - [key]: The environment variable key.
/// - [defaultValue]: The default value if the key is not found.
///
/// Returns the string value associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
String? envString(
  Ref ref,
  String key, {
  String? defaultValue,
}) {
  final envUseCase = EnvStringUseCase(
    repository: ref.watch(environmentRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return envUseCase.execute();
}
