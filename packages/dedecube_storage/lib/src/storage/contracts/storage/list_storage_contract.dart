import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';

/// Defines the contract for a list storage system.
abstract class ListStorageContract extends StorageContract {
  /// Attempts to retrieve a list storage variable.
  ///
  /// Returns the decoded [List<Map<String, dynamic>>] if found; otherwise `null`.
  Future<List<Map<String, dynamic>>?> tryGetList(String key);

  /// Retrieves a list storage variable.
  ///
  /// Returns the decoded [List<Map<String, dynamic>>] or [defaultValue] if not found.
  Future<List<Map<String, dynamic>>> getList(
    String key,
    List<Map<String, dynamic>> defaultValue,
  );

  /// Stores a list by encoding it into a JSON string.
  ///
  /// [list] is the [List<Map<String, dynamic>>] to be stored.
  Future<void> setList(String key, List<Map<String, dynamic>> list);
}
