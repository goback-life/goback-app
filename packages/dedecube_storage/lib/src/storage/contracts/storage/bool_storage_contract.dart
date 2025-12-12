import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';

abstract class BoolStorageContract extends StorageContract {
  /// Attempts to retrieve a boolean value.
  ///
  /// - [key]: The storage key.
  ///
  /// Returns the [bool] value associated with [key] or `null` if not found.
  Future<bool?> tryGetBool(String key);

  /// Retrieves a boolean value.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [bool] value associated with [key] or [defaultValue] if not found.
  Future<bool> getBool(String key, bool defaultValue);

  /// Sets a boolean value.
  ///
  /// - [key]: The storage key.
  /// - [value]: The boolean value to set.
  Future<void> setBool(String key, bool value);
}
