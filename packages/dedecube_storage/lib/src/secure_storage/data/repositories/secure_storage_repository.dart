import 'package:dedecube_storage/src/secure_storage/data/services/secure_storage_service.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_repository_contract.dart';

class SecureStorageRepository implements SecureStorageRepositoryContract {
  const SecureStorageRepository({required this.secureStorageService});

  final SecureStorageService secureStorageService;

  @override
  Future<String?> getString(String key, [String? defaultValue]) {
    return secureStorageService.getString(key, defaultValue);
  }

  @override
  Future<int?> getInt(String key, [int? defaultValue]) {
    return secureStorageService.getInt(key, defaultValue);
  }

  @override
  Future<double?> getDouble(String key, [double? defaultValue]) {
    return secureStorageService.getDouble(key, defaultValue);
  }

  @override
  Future<bool?> getBool(String key, [bool? defaultValue]) {
    return secureStorageService.getBool(key, defaultValue);
  }

  @override
  Future<void> setString(String key, String value) async {
    return await secureStorageService.setString(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    return await secureStorageService.setInt(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    return await secureStorageService.setDouble(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    return await secureStorageService.setBool(key, value);
  }

  @override
  Future<void> remove(String key) async {
    return await secureStorageService.remove(key);
  }

  @override
  Future<void> clear() async {
    return await secureStorageService.clear();
  }
}
