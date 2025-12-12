import 'dart:convert';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

/// [GetListUseCase] handles the retrieval of a list storage variable with a default value.
class GetListUseCase implements UseCaseContract<List<Map<String, dynamic>>?> {
  /// Creates an instance of [GetListUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [SecureStorageRepositoryContract] used to perform the retrieval.
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value to return if the key is not found or if decoding fails.
  const GetListUseCase({
    required this.repository,
    required this.key,
    this.defaultValue,
  });

  /// The repository responsible for storage retrieval operations.
  final SecureStorageRepositoryContract repository;

  /// The key for the storage variable.
  final String key;

  /// The default value to return if the key is not found or if decoding fails.
  final List<Map<String, dynamic>>? defaultValue;

  /// Executes the use case to retrieve a list storage value.
  ///
  /// Retrieves the JSON string via the repository's `getString` method and decodes it.
  ///
  /// Returns the decoded [List<Map<String, dynamic>>] or [defaultValue] if not found or decoding fails.
  @override
  Future<List<Map<String, dynamic>>?> execute() async {
    final jsonString = await repository.getString(key, null);
    if (jsonString == null) {
      return defaultValue;
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      }
      return defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }
}
