/// Defines the contract for the environment repository.
///
/// Any implementation of this contract must provide methods to retrieve
/// environment variables of various types.
abstract class EnvironmentRepositoryContract {
  /// Initializes the environment repository with the specified configuration file.
  ///
  /// This method loads the environment variables from the given [filename].
  /// If no filename is provided, it defaults to '.env'.
  ///
  /// Throws an exception if the initialization fails.
  ///
  /// - Parameters:
  ///   - filename: The name of the configuration file to load. Defaults to '.env'.
  ///
  /// - Returns: A [Future] that completes when the initialization is done.
  Future<void> initialize({String filename = '.env'});

  /// Retrieves a string environment variable.
  String? envString(String key, [String? defaultValue]);

  /// Retrieves an integer environment variable.
  int? envInt(String key, [int? defaultValue]);

  /// Retrieves a double environment variable.
  double? envDouble(String key, [double? defaultValue]);

  /// Retrieves a boolean environment variable.
  bool? envBool(String key, [bool? defaultValue]);
}
