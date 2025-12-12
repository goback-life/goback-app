import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/domain/contracts/environment_repository_contract.dart';

/// [EnvStringUseCase] handles the retrieval of string environment variables.
///
/// Implements the [`UseCaseContract<void>`](lib/src/domain/utilities/use_case_contract.dart)
/// to execute the retrieval operation.
class EnvStringUseCase implements UseCaseContract<void> {
  /// Creates an instance of [EnvStringUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`EnvironmentRepositoryContract`](lib/src/domain/contracts/environment_repository_contract.dart)
  ///   used to perform the retrieval.
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  const EnvStringUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for environment retrieval operations.
  final EnvironmentRepositoryContract repository;

  /// The key for the environment variable.
  final String key;

  /// The default value to return if the key is not found.
  final String? defaultValue;

  /// Executes the use case to retrieve a string environment value.
  ///
  /// Delegates the retrieval task to the [repository]'s
  /// [`envString`](lib/src/domain/contracts/environment_repository_contract.dart) method.
  ///
  /// Returns the string value associated with [key] or [defaultValue] if not found.
  @override
  String? execute() {
    return repository.envString(key, defaultValue);
  }
}
