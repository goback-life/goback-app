import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/domain/contracts/environment_repository_contract.dart';

/// [EnvIntUseCase] handles retrieval of integer environment variables.
///
/// Implements the [`UseCaseContract<void>`](lib/src/domain/utilities/use_case_contract.dart) to execute the retrieval operation.
class EnvIntUseCase implements UseCaseContract<void> {
  /// Creates an instance of [EnvIntUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`EnvironmentRepositoryContract`](lib/src/domain/contracts/environment_repository_contract.dart) used to perform the retrieval.
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  const EnvIntUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for environment retrieval operations.
  final EnvironmentRepositoryContract repository;

  /// The key for the environment variable.
  final String key;

  /// The default value to return if the key is not found.
  final int? defaultValue;

  /// Executes the use case to retrieve an integer environment value.
  ///
  /// Delegates the retrieval task to the [repository]'s [`envInt`](lib/src/domain/contracts/environment_repository_contract.dart) method.
  @override
  int? execute() {
    return repository.envInt(key, defaultValue);
  }
}
