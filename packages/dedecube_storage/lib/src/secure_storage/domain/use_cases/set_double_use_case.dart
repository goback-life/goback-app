import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [SetDoubleUseCase] handles setting a double storage variable.
class SetDoubleUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetDoubleUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SecureStorageRepositoryContract`](lib/src/domain/contracts/secure_storage_repository_contract.dart)
  ///   used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [value]: The double value to set.
  const SetDoubleUseCase({
    required this.repository,
    required this.key,
    required this.value,
  });

  /// The repository responsible for storage set operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The double value to set.
  final double value;

  /// Executes the use case to set a double storage value.
  ///
  /// Delegates the set task to the [repository]'s
  /// [`setDouble`](lib/src/domain/contracts/secure_storage_repository_contract.dart) method.
  @override
  Future<void> execute() async {
    return await repository.setDouble(key, value);
  }
}
