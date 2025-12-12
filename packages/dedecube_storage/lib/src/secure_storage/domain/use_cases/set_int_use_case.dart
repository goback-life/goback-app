import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [SetIntUseCase] handles setting an integer storage variable.
class SetIntUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetIntUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SecureStorageRepositoryContract`](lib/src/domain/contracts/secure_storage_repository_contract.dart)
  ///   used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [value]: The integer value to set.
  const SetIntUseCase({
    required this.repository,
    required this.key,
    required this.value,
  });

  /// The repository responsible for storage set operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The integer value to set.
  final int value;

  /// Executes the use case to set an integer storage value.
  ///
  /// Delegates the set task to the [repository]'s
  /// [`setInt`](lib/src/domain/contracts/secure_storage_repository_contract.dart) method.
  @override
  Future<void> execute() async {
    return await repository.setInt(key, value);
  }
}
