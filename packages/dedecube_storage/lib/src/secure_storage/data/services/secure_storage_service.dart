import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_service_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService implements SecureStorageServiceContract {
  SecureStorageService(
    Ref ref,
  ) {
    AndroidOptions getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    _storage = FlutterSecureStorage(aOptions: getAndroidOptions());
  }

  late FlutterSecureStorage _storage;

  @override
  Future<String?> getString(String key, [String? defaultValue]) async {
    return await _getValue<String?>(
      key,
      (storedValue) => storedValue,
      defaultValue,
    );
  }

  @override
  Future<int?> getInt(String key, [int? defaultValue]) async {
    return await _getValue<int?>(
      key,
      (storedValue) => storedValue != null ? int.tryParse(storedValue) : null,
      defaultValue,
    );
  }

  @override
  Future<double?> getDouble(String key, [double? defaultValue]) async {
    return await _getValue<double?>(
      key,
      (storedValue) =>
          storedValue != null ? double.tryParse(storedValue) : null,
      defaultValue,
    );
  }

  @override
  Future<bool?> getBool(String key, [bool? defaultValue]) async {
    return await _getValue<bool?>(
      key,
      (storedValue) {
        if (storedValue == null) {
          return null;
        }
        if (storedValue.toLowerCase() == 'true' ||
            storedValue.toLowerCase() == '1') {
          return true;
        }
        if (storedValue.toLowerCase() == 'false' ||
            storedValue.toLowerCase() == '0') {
          return false;
        }
        return null;
      },
      defaultValue,
    );
  }

  @override
  Future<void> setString(String key, String value) async {
    return await _storage.write(key: key, value: value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    final stringValue = value.toString();
    return await _storage.write(key: key, value: stringValue);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final stringValue = value.toString();
    return await _storage.write(key: key, value: stringValue);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final stringValue = value.toString();
    return await _storage.write(key: key, value: stringValue);
  }

  @override
  Future<void> remove(String key) async {
    return await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    return await _storage.deleteAll();
  }

  Future<T?>? _getValue<T>(
    String key,
    T? Function(String? storedValue) parser,
    T? defaultValue,
  ) async {
    try {
      if (await _keyExists(key)) {
        final storedValue = await _storage.read(key: key);
        final parsedValue = parser(storedValue);
        if (parsedValue != null) {
          return parsedValue;
        }
      }
    } on FormatException catch (e) {
      debugPrint('Error retrieving value for key $key: $e');
      return defaultValue;
    }

    debugPrint('Key $key not found. Returning default value: $defaultValue');
    return defaultValue;
  }

  Future<bool> _keyExists(String key) async {
    return await _storage.containsKey(key: key);
  }
}
