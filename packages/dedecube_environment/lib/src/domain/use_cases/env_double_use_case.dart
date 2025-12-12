import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/domain/contracts/environment_repository_contract.dart';

/// [EnvDoubleUseCase] handles retrieval of double environment variables.
///
/// Implements the [`UseCaseContract<void>`](lib/src/domain/utilities/use_case_contract.dart) to execute the retrieval operation.
class EnvDoubleUseCase implements UseCaseContract<void> {
  /// Creates an instance of [EnvDoubleUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`EnvironmentRepositoryContract`](lib/src/domain/contracts/environment_repository_contract.dart) used to perform the retrieval.
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  const EnvDoubleUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for environment retrieval operations.
  final EnvironmentRepositoryContract repository;

  /// The key for the environment variable.
  final String key;

  /// The default value to return if the key is not found.
  final double? defaultValue;

  /// Executes the use case to retrieve a double environment value.
  ///
  /// Delegates the retrieval task to the [repository]'s [`envDouble`](lib/src/domain/contracts/environment_repository_contract.dart) method.
  @override
  double? execute() {
    return repository.envDouble(key, defaultValue);
  }
}
