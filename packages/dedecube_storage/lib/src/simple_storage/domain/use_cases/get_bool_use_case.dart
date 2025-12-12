import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [GetBoolUseCase] handles the retrieval of a boolean storage variable with a default value.
class GetBoolUseCase implements UseCaseContract<void> {
  /// Creates an instance of [GetBoolUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SimpleStorageRepositoryContract`](lib/src/domain/contracts/simple_storage_repository_contract.dart)
  ///   used to perform the retrieval.
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found.
  const GetBoolUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for storage retrieval operations.
  final SimpleStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The default value to return if the key is not found.
  final bool? defaultValue;

  /// Executes the use case to retrieve a boolean storage value.
  ///
  /// Delegates the retrieval task to the [repository]'s
  /// [`getBool`](lib/src/domain/contracts/simple_storage_repository_contract.dart) method.
  ///
  /// Returns the boolean value associated with [key] or [defaultValue] if not found.
  @override
  bool? execute() {
    return repository.getBool(key, defaultValue);
  }
}
