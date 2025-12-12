import 'package:dedecube_storage/src/simple_storage/data/services/simple_storage_service.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_repository_contract.dart';

class SimpleStorageRepository implements SimpleStorageRepositoryContract {
  const SimpleStorageRepository({required this.simpleStorageService});

  final SimpleStorageService simpleStorageService;

  @override
  Future<void> initialize() async {
    return await simpleStorageService.initialize();
  }

  @override
  String? getString(String key, [String? defaultValue]) {
    return simpleStorageService.getString(key, defaultValue);
  }

  @override
  int? getInt(String key, [int? defaultValue]) {
    return simpleStorageService.getInt(key, defaultValue);
  }

  @override
  double? getDouble(String key, [double? defaultValue]) {
    return simpleStorageService.getDouble(key, defaultValue);
  }

  @override
  bool? getBool(String key, [bool? defaultValue]) {
    return simpleStorageService.getBool(key, defaultValue);
  }

  @override
  Future<bool> setString(String key, String value) async {
    return await simpleStorageService.setString(key, value);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    return await simpleStorageService.setInt(key, value);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    return await simpleStorageService.setDouble(key, value);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return await simpleStorageService.setBool(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    return await simpleStorageService.remove(key);
  }

  @override
  Future<bool> clear() async {
    return await simpleStorageService.clear();
  }
}
