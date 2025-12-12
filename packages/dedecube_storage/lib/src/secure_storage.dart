import 'dart:core';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_contract.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/clear_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/get_bool_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/get_double_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/get_int_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/get_string_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/remove_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/set_bool_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/set_double_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/set_int_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/providers/set_string_provider.dart';

/// A [SecureStorage] class to handle storage variable operations.
///
/// This class provides methods to access, modify, and manage storage variables
/// of different types and ensures default values are returned or actions are
/// performed when variables are not found or need to be modified.
class SecureStorage implements SecureStorageContract {
  /// Creates a [SecureStorage] instance.
  SecureStorage();

  /// Attempts to retrieve a string storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [String] value associated with [key] or `null` if not found.
  @override
  Future<String?> tryGetString(String key) async {
    return await riverpodContainer().read(getStringProvider(key).future);
  }

  /// Retrieves a string storage variable.
  ///
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [String] value associated with [key] or [defaultValue] if not found.
  @override
  Future<String> getString(
    String key,
    String defaultValue,
  ) async {
    final Future<String?> futureBool = riverpodContainer()
        .read(getStringProvider(key, defaultValue: defaultValue).future);
    final String? result = await futureBool;
    return result ?? defaultValue;
  }

  /// Attempts to retrieve an integer storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [int] value associated with [key] or `null` if not found.
  @override
  Future<int?> tryGetInt(String key) {
    return riverpodContainer().read(getIntProvider(key).future);
  }

  /// Retrieves an integer storage variable.
  ///
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [int] value associated with [key] or [defaultValue] if not found.
  @override
  Future<int> getInt(String key, int defaultValue) async {
    final Future<int?> futureBool = riverpodContainer()
        .read(getIntProvider(key, defaultValue: defaultValue).future);
    final int? result = await futureBool;
    return result ?? defaultValue;
  }

  /// Attempts to retrieve a double storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [double] value associated with [key] or `null` if not found.
  @override
  Future<double?> tryGetDouble(String key) {
    return riverpodContainer().read(getDoubleProvider(key).future);
  }

  /// Retrieves a double storage variable.
  ///
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [double] value associated with [key] or [defaultValue] if not found.
  @override
  Future<double> getDouble(String key, double defaultValue) async {
    final Future<double?> futureBool = riverpodContainer()
        .read(getDoubleProvider(key, defaultValue: defaultValue).future);
    final double? result = await futureBool;
    return result ?? defaultValue;
  }

  /// Attempts to retrieve a boolean storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [bool] value associated with [key] or `null` if not found.
  @override
  Future<bool?> tryGetBool(String key) {
    return riverpodContainer().read(getBoolProvider(key).future);
  }

  /// Retrieves a boolean storage variable.
  ///
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found.
  ///
  /// Returns the [bool] value associated with [key] or [defaultValue] if not found.
  @override
  Future<bool> getBool(String key, bool defaultValue) async {
    final Future<bool?> futureBool = riverpodContainer()
        .read(getBoolProvider(key, defaultValue: defaultValue).future);
    final bool? result = await futureBool;
    return result ?? defaultValue;
  }

  @override
  Future<void> setString(String key, String value) async {
    return await riverpodContainer().read(setStringProvider(key, value).future);
  }

  @override
  Future<void> setInt(String key, int value) async {
    return await riverpodContainer().read(setIntProvider(key, value).future);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    return await riverpodContainer().read(setDoubleProvider(key, value).future);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    return await riverpodContainer().read(setBoolProvider(key, value).future);
  }

  @override
  Future<void> remove(String key) async {
    return await riverpodContainer().read(removeProvider(key).future);
  }

  @override
  Future<void> clear() async {
    return await riverpodContainer().read(clearProvider.future);
  }
}

SecureStorageContract get secureStorage => GetIt.I<SecureStorageContract>();
