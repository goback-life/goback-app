import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [SetStringUseCase] handles setting a string storage variable.
class SetStringUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetStringUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`SecureStorageRepositoryContract`](lib/src/domain/contracts/secure_storage_repository_contract.dart)
  ///   used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [value]: The string value to set.
  const SetStringUseCase({
    required this.repository,
    required this.key,
    required this.value,
  });

  /// The repository responsible for storage set operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The string value to set.
  final String value;

  /// Executes the use case to set a string storage value.
  ///
  /// Delegates the set task to the [repository]'s
  /// [`setString`](lib/src/domain/contracts/secure_storage_repository_contract.dart) method.
  @override
  Future<void> execute() async {
    return await repository.setString(key, value);
  }
}
