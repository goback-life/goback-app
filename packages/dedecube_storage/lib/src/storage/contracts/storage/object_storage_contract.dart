import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';

/// Defines the contract for an object storage system.
abstract class ObjectStorageContract extends StorageContract {
  /// Attempts to retrieve an object storage variable.
  ///
  /// Returns the decoded [Map<String, dynamic>] if found; otherwise `null`.
  Future<Map<String, dynamic>?> tryGetObject(String key);

  /// Retrieves an object storage variable.
  ///
  /// Returns the decoded [Map<String, dynamic>] or [defaultValue] if not found.
  Future<Map<String, dynamic>> getObject(
    String key,
    Map<String, dynamic> defaultValue,
  );

  /// Stores an object by encoding it into a JSON string.
  ///
  /// [object] is the [Map<String, dynamic>] that represents the object to store.
  Future<void> setObject(String key, Map<String, dynamic> object);
}
