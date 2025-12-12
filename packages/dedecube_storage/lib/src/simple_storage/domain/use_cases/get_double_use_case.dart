import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [GetDoubleUseCase] handles the retrieval of a double storage variable with a default value.
class GetDoubleUseCase implements UseCaseContract<void> {
  /// Creates an instance of [GetDoubleUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SimpleStorageRepositoryContract`](lib/src/domain/contracts/simple_storage_repository_contract.dart)
  ///   used to perform the retrieval.
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found.
  const GetDoubleUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for storage retrieval operations.
  final SimpleStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The default value to return if the key is not found.
  final double? defaultValue;

  /// Executes the use case to retrieve a double storage value.
  ///
  /// Delegates the retrieval task to the [repository]'s
  /// [`getDouble`](lib/src/domain/contracts/simple_storage_repository_contract.dart) method.
  ///
  /// Returns the double value associated with [key] or [defaultValue] if not found.
  @override
  double? execute() {
    return repository.getDouble(key, defaultValue);
  }
}
