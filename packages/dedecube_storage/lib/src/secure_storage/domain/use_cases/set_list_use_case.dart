import 'dart:convert';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [SetListUseCase] handles setting a list storage variable.
///
/// The provided list should contain objects convertible to a [Map<String, dynamic>].
/// The list is encoded as a JSON string before storing.
class SetListUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetListUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [SecureStorageRepositoryContract] used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [list]: The list of objects to set (each as a Map).
  const SetListUseCase({
    required this.repository,
    required this.key,
    required this.list,
  });

  /// The repository responsible for storage set operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The list of objects to store.
  final List<Map<String, dynamic>> list;

  /// Executes the use case to set a list storage value.
  ///
  /// The [list] is encoded to a JSON string and then stored using the repository's
  /// `setString` method.
  @override
  Future<void> execute() async {
    final jsonString = json.encode(list);
    return await repository.setString(key, jsonString);
  }
}
