import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [ClearUseCase] handles the clearing of all storage variables.
class ClearUseCase implements UseCaseContract<void> {
  /// Creates an instance of [ClearUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SimpleStorageRepositoryContract`](lib/src/domain/contracts/simple_storage_repository_contract.dart)
  ///   used to perform the clear operation.
  const ClearUseCase({
    required this.repository,
  });

  /// The repository responsible for storage clear operations.
  final SimpleStorageRepositoryContract repository;

  /// Executes the use case to clear all storage variables.
  ///
  /// Delegates the clear task to the [repository]'s
  /// [`clear`](lib/src/domain/contracts/simple_storage_repository_contract.dart) method.
  @override
  Future<bool> execute() async {
    return await repository.clear();
  }
}
