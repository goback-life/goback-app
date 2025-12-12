import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [RemoveUseCase] handles the removal of a storage variable.
class RemoveUseCase implements UseCaseContract<void> {
  /// Creates an instance of [RemoveUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SimpleStorageRepositoryContract`](lib/src/domain/contracts/simple_storage_repository_contract.dart)
  ///   used to perform the removal.
  /// - [key]: The storage variable key to remove.
  const RemoveUseCase({
    required this.repository,
    required this.key,
  });

  /// The repository responsible for storage removal operations.
  final SimpleStorageRepositoryContract repository;

  /// The key for the storage variable to remove.
  final String key;

  /// Executes the use case to remove a storage variable.
  ///
  /// Delegates the removal task to the [repository]'s
  /// [`remove`](lib/src/domain/contracts/simple_storage_repository_contract.dart) method.
  @override
  Future<bool> execute() async {
    return await repository.remove(key);
  }
}
