import 'dart:core';

import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_contract.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/clear_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/get_bool_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/get_double_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/get_int_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/get_list_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/get_object_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/get_string_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/initialize_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/remove_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/set_bool_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/set_double_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/set_int_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/set_list_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/set_object_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/providers/set_string_provider.dart';

/// A [SimpleStorage] class to handle storage variable operations.
///
/// This class provides methods to access, modify, and manage storage variables
/// of different types and ensures default values are returned or actions are
/// performed when variables are not found or need to be modified.
class SimpleStorage implements SimpleStorageContract {
  /// Creates a [SimpleStorage] instance.
  SimpleStorage();

  @override
  Future<void> initialize({String? filename}) async {
    await riverpodContainer().read(initializeProvider.future);
  }

  /// Attempts to retrieve a string storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [String] value associated with [key] or `null` if not found.
  @override
  Future<String?> tryGetString(String key) async {
    return riverpodContainer().read(getStringProvider(key).future);
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
    final provider = getStringProvider(key, defaultValue: defaultValue);
    final result =
        await riverpodContainer().read<Future<String?>>(provider.future);
    return result ?? defaultValue;
  }

  /// Attempts to retrieve an integer storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [int] value associated with [key] or `null` if not found.
  @override
  Future<int?> tryGetInt(String key) async {
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
    final provider = getIntProvider(key, defaultValue: defaultValue);
    final result =
        await riverpodContainer().read<Future<int?>>(provider.future);
    return result ?? defaultValue;
  }

  /// Attempts to retrieve a double storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [double] value associated with [key] or `null` if not found.
  @override
  Future<double?> tryGetDouble(String key) async {
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
    final provider = getDoubleProvider(key, defaultValue: defaultValue);
    final result =
        await riverpodContainer().read<Future<double?>>(provider.future);
    return result ?? defaultValue;
  }

  /// Attempts to retrieve a boolean storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the [bool] value associated with [key] or `null` if not found.
  @override
  Future<bool?> tryGetBool(String key) async {
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
    final provider = getBoolProvider(key, defaultValue: defaultValue);
    final result =
        await riverpodContainer().read<Future<bool?>>(provider.future);
    return result ?? defaultValue;
  }

  /// Attempts to retrieve an object storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the decoded [Map<String, dynamic>] if found and decodable; otherwise `null`.
  @override
  Future<Map<String, dynamic>?> tryGetObject(String key) async {
    return riverpodContainer().read(getObjectProvider(key).future);
  }

  /// Retrieves an object storage variable.
  ///
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found or decoding fails.
  ///
  /// Returns the decoded [Map<String, dynamic>] or [defaultValue] if not found.
  @override
  Future<Map<String, dynamic>> getObject(
    String key,
    Map<String, dynamic> defaultValue,
  ) async {
    final provider = getObjectProvider(key, defaultValue: defaultValue);
    final result = await riverpodContainer()
        .read<Future<Map<String, dynamic>?>>(provider.future);
    return result ?? defaultValue;
  }

  /// Attempts to retrieve a list storage variable.
  ///
  /// - [key]: The storage variable key.
  ///
  /// Returns the decoded [List<Map<String, dynamic>>] if found and decodable; otherwise `null`.
  @override
  Future<List<Map<String, dynamic>>?> tryGetList(String key) async {
    return riverpodContainer().read(getListProvider(key).future);
  }

  /// Retrieves a list storage variable.
  ///
  /// - [key]: The storage variable key.
  /// - [defaultValue]: The default value if the key is not found or decoding fails.
  ///
  /// Returns the decoded [List<Map<String, dynamic>>] or [defaultValue] if not found.
  @override
  Future<List<Map<String, dynamic>>> getList(
    String key,
    List<Map<String, dynamic>> defaultValue,
  ) async {
    final provider = getListProvider(key, defaultValue: defaultValue);
    final result = await riverpodContainer()
        .read<Future<List<Map<String, dynamic>>?>>(provider.future);
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
  Future<void> setObject(String key, Map<String, dynamic> object) async {
    return await riverpodContainer()
        .read(setObjectProvider(key, object).future);
  }

  @override
  Future<void> setList(String key, List<Map<String, dynamic>> list) async {
    return await riverpodContainer().read(setListProvider(key, list).future);
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

SimpleStorageContract get simpleStorage => GetIt.I<SimpleStorageContract>();
