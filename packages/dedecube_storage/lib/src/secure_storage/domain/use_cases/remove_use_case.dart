import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [RemoveUseCase] handles the removal of a storage variable.
class RemoveUseCase implements UseCaseContract<void> {
  /// Creates an instance of [RemoveUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SecureStorageRepositoryContract`](lib/src/domain/contracts/secure_storage_repository_contract.dart)
  ///   used to perform the removal.
  /// - [key]: The storage variable key to remove.
  const RemoveUseCase({
    required this.repository,
    required this.key,
  });

  /// The repository responsible for storage removal operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable to remove.
  final String key;

  /// Executes the use case to remove a storage variable.
  ///
  /// Delegates the removal task to the [repository]'s
  /// [`remove`](lib/src/domain/contracts/secure_storage_repository_contract.dart) method.
  @override
  Future<void> execute() async {
    return await repository.remove(key);
  }
}
