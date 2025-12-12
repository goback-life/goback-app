import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_service_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleStorageService implements SimpleStorageServiceContract {
  SimpleStorageService(
    Ref ref,
  );

  @override
  Future<void> initialize() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  late SharedPreferences _sharedPreferences;

  @override
  String? getString(String key, [String? defaultValue]) {
    return _getValue<String?>(
      key,
      _sharedPreferences.getString,
      defaultValue,
    );
  }

  @override
  int? getInt(String key, [int? defaultValue]) {
    return _getValue<int?>(
      key,
      _sharedPreferences.getInt,
      defaultValue,
    );
  }

  @override
  double? getDouble(String key, [double? defaultValue]) {
    return _getValue<double?>(
      key,
      _sharedPreferences.getDouble,
      defaultValue,
    );
  }

  @override
  bool? getBool(String key, [bool? defaultValue]) {
    return _getValue<bool?>(
      key,
      _sharedPreferences.getBool,
      defaultValue,
    );
  }

  @override
  Future<bool> setString(String key, String value) async {
    return await _sharedPreferences.setString(key, value);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    return await _sharedPreferences.setInt(key, value);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    return await _sharedPreferences.setDouble(key, value);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return await _sharedPreferences.setBool(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    return await _sharedPreferences.remove(key);
  }

  @override
  Future<bool> clear() async {
    return await _sharedPreferences.clear();
  }

  T? _getValue<T>(
    String key,
    T Function(String key) getter, [
    T? defaultValue,
  ]) {
    try {
      if (_keyExists(key)) {
        return getter(key);
      }
    } on FormatException catch (e) {
      debugPrint('Error retrieving value for key $key: $e');
      return defaultValue;
    }

    debugPrint('Key $key not found. Returning default value: $defaultValue');
    return defaultValue;
  }

  bool _keyExists(String key) {
    return _sharedPreferences.containsKey(key);
  }
}
