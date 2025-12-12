import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';

abstract class StringStorageContract extends StorageContract {
  /// Attempts to retrieve a string value.
  ///
  /// - [key]: The storage key.
  ///
  /// Returns the [String] value associated with [key] or `null` if not found.
  Future<String?> tryGetString(String key);

  /// Retrieves a string value.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [String] value associated with [key] or [defaultValue] if not found.
  Future<String> getString(String key, String defaultValue);

  /// Sets a string value.
  ///
  /// - [key]: The storage key.
  /// - [value]: The string value to set.
  Future<void> setString(String key, String value);
}
