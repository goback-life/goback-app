import 'dart:convert';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [GetObjectUseCase] handles the retrieval of an object storage variable with a default value.
class GetObjectUseCase implements UseCaseContract<Map<String, dynamic>?> {
  /// Creates an instance of [GetObjectUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [SecureStorageRepositoryContract] used to perform the retrieval.
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value to return if the key is not found.
  const GetObjectUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for storage retrieval operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The default value to return if the key is not found or if decoding fails.
  final Map<String, dynamic>? defaultValue;

  /// Executes the use case to retrieve an object storage value.
  ///
  /// Retrieves the JSON string via the repository's `getString` method and decodes it.
  ///
  /// Returns the decoded [Map<String, dynamic>] or [defaultValue] if not found or decoding fails.
  @override
  Future<Map<String, dynamic>?> execute() async {
    final jsonString = await repository.getString(key, null);
    if (jsonString == null) {
      return defaultValue;
    }
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return defaultValue;
    }
  }
}
