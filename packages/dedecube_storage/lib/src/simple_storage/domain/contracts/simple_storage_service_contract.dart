/// Defines the contract for the simple storage service.
///
/// Any implementation of this contract must provide methods to manage
/// storage variables of various types.
abstract class SimpleStorageServiceContract {
  /// Initializes the storage with the required providers.
  Future<void> initialize();

  /// Retrieves a string value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [String] value associated with [key] or [defaultValue] if not found.
  String? getString(String key, String defaultValue);

  /// Retrieves an integer value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [int] value associated with [key] or [defaultValue] if not found.
  int? getInt(String key, int defaultValue);

  /// Retrieves a double value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [double] value associated with [key] or [defaultValue] if not found.
  double? getDouble(String key, double defaultValue);

  /// Retrieves a boolean value from storage.
  ///
  /// - [key]: The storage key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [bool] value associated with [key] or [defaultValue] if not found.
  bool? getBool(String key, bool defaultValue);

  /// Sets a string value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The string value to set.
  Future<bool> setString(String key, String value);

  /// Sets an integer value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The integer value to set.
  Future<bool> setInt(String key, int value);

  /// Sets a double value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The double value to set.
  Future<bool> setDouble(String key, double value);

  /// Sets a boolean value in storage.
  ///
  /// - [key]: The storage key.
  /// - [value]: The boolean value to set.
  Future<bool> setBool(String key, bool value);

  /// Removes a value from storage.
  ///
  /// - [key]: The storage key to remove.
  Future<bool> remove(String key);

  /// Clears all values from storage.
  Future<bool> clear();
}
