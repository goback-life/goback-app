import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [GetStringUseCase] handles the retrieval of a string environment variable with a default value.
class GetStringUseCase implements UseCaseContract<void> {
  /// Creates an instance of [GetStringUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`EnvironmentRepositoryContract`](lib/src/domain/contracts/environment_repository_contract.dart)
  ///   used to perform the retrieval.
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  const GetStringUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for environment retrieval operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the environment variable.
  final String key;

  /// The default value to return if the key is not found.
  final String? defaultValue;

  /// Executes the use case to retrieve a string environment value.
  ///
  /// Delegates the retrieval task to the [repository]'s
  /// [`getString`](lib/src/domain/contracts/secure_storage_repository_contract.dart) method.
  ///
  /// Returns the string value associated with [key] or [defaultValue] if not found.
  @override
  Future<String?> execute() async {
    return await repository.getString(key, defaultValue);
  }
}
