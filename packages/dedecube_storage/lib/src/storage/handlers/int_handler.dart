import 'package:dedecube_storage/src/storage/contracts/data_handler_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/int_storage_contract.dart';

class IntHandler extends DataHandlerContract<int, IntStorageContract> {
  @override
  Future<int?> tryGet(
    String key,
    IntStorageContract storage, {
    int? defaultValue,
  }) async {
    return await storage.tryGetInt(key) ?? defaultValue;
  }

  @override
  Future<int> get(
    String key,
    IntStorageContract storage,
    int defaultValue,
  ) async {
    return await storage.getInt(key, defaultValue);
  }

  @override
  Future<void> set(String key, IntStorageContract storage, int value) async {
    await storage.setInt(key, value);
  }

  @override
  Future<void> remove(String key, IntStorageContract storage) async {
    await storage.remove(key);
  }
}
