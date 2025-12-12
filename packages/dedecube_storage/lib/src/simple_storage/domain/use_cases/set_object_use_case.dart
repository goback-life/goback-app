import 'dart:convert';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

/// [SetObjectUseCase] handles setting an object storage variable.
///
/// The provided object should be convertible to a [Map<String, dynamic>].
/// The object is encoded as a JSON string before storing.
class SetObjectUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetObjectUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [SimpleStorageRepositoryContract] used to perform the set operation.
  /// - [key]: The storage variable key.
  /// - [object]: The object to set (as a Map).
  const SetObjectUseCase({
    required this.repository,
    required this.key,
    required this.object,
  });

  /// The repository responsible for storage set operations.
  final SimpleStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The object to store.
  final Map<String, dynamic> object;

  /// Executes the use case to set an object storage value.
  ///
  /// The [object] is encoded to a JSON string and then stored using the repository's
  /// `setString` method.
  @override
  Future<bool> execute() async {
    final jsonString = json.encode(object);
    return await repository.setString(key, jsonString);
  }
}
