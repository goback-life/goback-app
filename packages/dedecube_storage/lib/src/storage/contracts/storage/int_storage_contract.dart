import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';

abstract class IntStorageContract extends StorageContract {
  /// Attempts to retrieve an integer value.
  ///
  /// - [key]: The storage key.
  ///
  /// Returns the [int] value associated with [key] or `null` if not found.
  Future<int?> tryGetInt(String key);

  /// Retrieves an integer value.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [int] value associated with [key] or [defaultValue] if not found.
  Future<int> getInt(String key, int defaultValue);

  /// Sets an integer value.
  ///
  /// - [key]: The storage key.
  /// - [value]: The integer value to set.
  Future<void> setInt(String key, int value);
}
