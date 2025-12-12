import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [SetBoolUseCase] handles setting a boolean storage variable.
class SetBoolUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetBoolUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SimpleStorageRepositoryContract`](lib/src/domain/contracts/simple_storage_repository_contract.dart)
  ///   used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [value]: The boolean value to set.
  const SetBoolUseCase({
    required this.repository,
    required this.key,
    required this.value,
  });

  /// The repository responsible for storage set operations.
  final SimpleStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The boolean value to set.
  final bool value;

  /// Executes the use case to set a boolean storage value.
  ///
  /// Delegates the set task to the [repository]'s
  /// [`setBool`](lib/src/domain/contracts/simple_storage_repository_contract.dart) method.
  @override
  Future<bool> execute() async {
    return await repository.setBool(key, value);
  }
}
