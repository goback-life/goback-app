import 'package:dedecube_storage/src/storage/contracts/data_handler_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/bool_storage_contract.dart';

class BoolHandler extends DataHandlerContract<bool, BoolStorageContract> {
  @override
  Future<bool?> tryGet(
    String key,
    BoolStorageContract storage, {
    bool? defaultValue,
  }) async {
    return await storage.tryGetBool(key) ?? defaultValue;
  }

  @override
  Future<bool> get(
    String key,
    BoolStorageContract storage,
    bool defaultValue,
  ) async {
    return await storage.getBool(key, defaultValue);
  }

  @override
  Future<void> set(String key, BoolStorageContract storage, bool value) async {
    await storage.setBool(key, value);
  }

  @override
  Future<void> remove(String key, BoolStorageContract storage) async {
    await storage.remove(key);
  }
}
