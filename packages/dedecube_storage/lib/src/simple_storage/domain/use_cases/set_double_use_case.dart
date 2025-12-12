import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [SetDoubleUseCase] handles setting a double storage variable.
class SetDoubleUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetDoubleUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SimpleStorageRepositoryContract`](lib/src/domain/contracts/simple_storage_repository_contract.dart)
  ///   used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [value]: The double value to set.
  const SetDoubleUseCase({
    required this.repository,
    required this.key,
    required this.value,
  });

  /// The repository responsible for storage set operations.
  final SimpleStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The double value to set.
  final double value;

  /// Executes the use case to set a double storage value.
  ///
  /// Delegates the set task to the [repository]'s
  /// [`setDouble`](lib/src/domain/contracts/simple_storage_repository_contract.dart) method.
  @override
  Future<bool> execute() async {
    return await repository.setDouble(key, value);
  }
}
