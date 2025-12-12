import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [GetIntUseCase] handles the retrieval of an integer storage variable with a default value.
class GetIntUseCase implements UseCaseContract<void> {
  /// Creates an instance of [GetIntUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SimpleStorageRepositoryContract`](lib/src/domain/contracts/simple_storage_repository_contract.dart)
  ///   used to perform the retrieval.
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found.
  const GetIntUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for storage retrieval operations.
  final SimpleStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The default value to return if the key is not found.
  final int? defaultValue;

  /// Executes the use case to retrieve an integer storage value.
  ///
  /// Delegates the retrieval task to the [repository]'s
  /// [`getInt`](lib/src/domain/contracts/simple_storage_repository_contract.dart) method.
  ///
  /// Returns the integer value associated with [key] or [defaultValue] if not found.
  @override
  int? execute() {
    return repository.getInt(key, defaultValue);
  }
}
