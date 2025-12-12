import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [SetBoolUseCase] handles setting a boolean storage variable.
class SetBoolUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetBoolUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SecureStorageRepositoryContract`](lib/src/domain/contracts/secure_storage_repository_contract.dart)
  ///   used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [value]: The boolean value to set.
  const SetBoolUseCase({
    required this.repository,
    required this.key,
    required this.value,
  });

  /// The repository responsible for storage set operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The boolean value to set.
  final bool value;

  /// Executes the use case to set a boolean storage value.
  ///
  /// Delegates the set task to the [repository]'s
  /// [`setBool`](lib/src/domain/contracts/secure_storage_repository_contract.dart) method.
  @override
  Future<void> execute() async {
    return await repository.setBool(key, value);
  }
}
