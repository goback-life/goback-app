/// A contract for the Environment class, defining the required methods and properties.
abstract class EnvironmentContract {
  /// Initializes the environment with the required providers.
  ///
  /// - [filename]: The name of the environment file to load.
  Future<void> initialize({String? filename});

  /// Attempts to retrieve a general environment variable as a [String].
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [String] value associated with [key] or `null` if not found.
  String? tryGetString(String key);

  /// Retrieves a general environment variable as a [String].
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [String] value associated with [key] or [defaultValue] if not found.
  String getString(String key, String defaultValue);

  /// Attempts to retrieve an integer environment variable.
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [int] value associated with [key] or `null` if not found.
  int? tryGetInt(String key);

  /// Retrieves an integer environment variable.
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [int] value associated with [key] or [defaultValue] if not found.
  int getInt(String key, int defaultValue);

  /// Attempts to retrieve a double environment variable.
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [double] value associated with [key] or `null` if not found.
  double? tryGetDouble(String key);

  /// Retrieves a double environment variable.
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [double] value associated with [key] or [defaultValue] if not found.
  double getDouble(String key, double defaultValue);

  /// Attempts to retrieve a boolean environment variable.
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [bool] value associated with [key] or `null` if not found.
  bool? tryGetBool(String key);

  /// Retrieves a boolean environment variable.
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [bool] value associated with [key] or [defaultValue] if not found.
  bool getBool(String key, bool defaultValue);
}
