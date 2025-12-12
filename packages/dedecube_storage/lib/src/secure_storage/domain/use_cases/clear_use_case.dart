import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [ClearUseCase] handles the clearing of all storage variables.
class ClearUseCase implements UseCaseContract<void> {
  /// Creates an instance of [ClearUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SecureStorageRepositoryContract`](lib/src/domain/contracts/secure_storage_repository_contract.dart)
  ///   used to perform the clear operation.
  const ClearUseCase({
    required this.repository,
  });

  /// The repository responsible for storage clear operations.
  final SecureStorageRepositoryContract repository;

  /// Executes the use case to clear all storage variables.
  ///
  /// Delegates the clear task to the [repository]'s
  /// [`clear`](lib/src/domain/contracts/secure_storage_repository_contract.dart) method.
  @override
  Future<void> execute() async {
    return await repository.clear();
  }
}
