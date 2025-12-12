import 'dart:core';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/domain/contracts/environment_contract.dart';
import 'package:dedecube_environment/src/domain/providers/env_bool_provider.dart';
import 'package:dedecube_environment/src/domain/providers/env_double_provider.dart';
import 'package:dedecube_environment/src/domain/providers/env_int_provider.dart';
import 'package:dedecube_environment/src/domain/providers/env_string_provider.dart';
import 'package:dedecube_environment/src/domain/providers/initialize_provider.dart';

/// A [Environment] class to handle environment variable retrieval operations.
///
/// This class provides methods to access environment variables of different types
/// and ensures default values are returned when variables are not found.
class Environment implements EnvironmentContract {
  /// Creates an [Environment] instance.
  ///
  /// - Initializes the environment with the required providers.
  Environment();

  @override
  Future<void> initialize({String? filename}) async {
    await riverpodContainer()
        .read(initializeProvider(filename ?? '.env').future);
  }

  /// Attempts to retrieve a string environment variable.
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [String] value associated with [key] or `null` if not found.
  @override
  String? tryGetString(String key) {
    return riverpodContainer().read(envStringProvider(key));
  }

  /// Retrieves a string environment variable.
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [String] value associated with [key] or [defaultValue] if not found.
  @override
  String getString(
    String key,
    String defaultValue,
  ) {
    return riverpodContainer()
            .read(envStringProvider(key, defaultValue: defaultValue)) ??
        defaultValue;
  }

  /// Attempts to retrieve an integer environment variable.
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [int] value associated with [key] or `null` if not found.
  @override
  int? tryGetInt(String key) {
    return riverpodContainer().read(envIntProvider(key));
  }

  /// Retrieves an integer environment variable.
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [int] value associated with [key] or [defaultValue] if not found.
  @override
  int getInt(String key, int defaultValue) {
    return riverpodContainer()
            .read(envIntProvider(key, defaultValue: defaultValue)) ??
        defaultValue;
  }

  /// Attempts to retrieve a double environment variable.
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [double] value associated with [key] or `null` if not found.
  @override
  double? tryGetDouble(String key) {
    return riverpodContainer().read(envDoubleProvider(key));
  }

  /// Retrieves a double environment variable.
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [double] value associated with [key] or [defaultValue] if not found.
  @override
  double getDouble(String key, double defaultValue) {
    return riverpodContainer()
            .read(envDoubleProvider(key, defaultValue: defaultValue)) ??
        defaultValue;
  }

  /// Attempts to retrieve a boolean environment variable.
  ///
  /// - [key]: The environment variable key.
  ///
  /// Returns the [bool] value associated with [key] or `null` if not found.
  @override
  bool? tryGetBool(String key) {
    return riverpodContainer().read(envBoolProvider(key));
  }

  /// Retrieves a boolean environment variable.
  ///
  /// - [key]: The environment variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [bool] value associated with [key] or [defaultValue] if not found.
  @override
  bool getBool(String key, bool defaultValue) {
    return riverpodContainer()
            .read(envBoolProvider(key, defaultValue: defaultValue)) ??
        defaultValue;
  }
}

EnvironmentContract get environment => GetIt.I<EnvironmentContract>();
