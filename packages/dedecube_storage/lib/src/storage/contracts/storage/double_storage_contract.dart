import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';

abstract class DoubleStorageContract extends StorageContract {
  /// Attempts to retrieve a double value.
  ///
  /// - [key]: The storage key.
  ///
  /// Returns the [double] value associated with [key] or `null` if not found.
  Future<double?> tryGetDouble(String key);

  /// Retrieves a double value.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [double] value associated with [key] or [defaultValue] if not found.
  Future<double> getDouble(String key, double defaultValue);

  /// Sets a double value.
  ///
  /// - [key]: The storage key.
  /// - [value]: The double value to set.
  Future<void> setDouble(String key, double value);
}
