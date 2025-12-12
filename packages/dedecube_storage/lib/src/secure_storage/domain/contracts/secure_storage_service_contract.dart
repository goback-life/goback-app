/// Defines the contract for the simple storage service.
///
/// Any implementation of this contract must provide methods to manage
/// storage variables of various types.
abstract class SecureStorageServiceContract {
  /// Retrieves a string value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [String] value associated with [key] or [defaultValue] if not found.
  Future<String?> getString(String key, String defaultValue);

  /// Retrieves an integer value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [int] value associated with [key] or [defaultValue] if not found.
  Future<int?> getInt(String key, int defaultValue);

  /// Retrieves a double value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [double] value associated with [key] or [defaultValue] if not found.
  Future<double?> getDouble(String key, double defaultValue);

  /// Retrieves a boolean value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [bool] value associated with [key] or [defaultValue] if not found.
  Future<bool?> getBool(String key, bool defaultValue);

  /// Sets a string value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The string value to set.
  Future<void> setString(String key, String value);

  /// Sets an integer value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The integer value to set.
  Future<void> setInt(String key, int value);

  /// Sets a double value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The double value to set.
  Future<void> setDouble(String key, double value);

  /// Sets a boolean value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The boolean value to set.
  Future<void> setBool(String key, bool value);

  /// Removes a value from storage.
  ///
  /// - [key]: The storage key to remove.
  Future<void> remove(String key);

  /// Clears all values from storage.
  Future<void> clear();
}
