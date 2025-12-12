import 'package:dedecube_storage/src/storage/contracts/data_handler_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/list_storage_contract.dart';

class ListHandler extends DataHandlerContract<List<Map<String, dynamic>>,
    ListStorageContract> {
  @override
  Future<List<Map<String, dynamic>>?> tryGet(
    String key,
    ListStorageContract storage, {
    List<Map<String, dynamic>>? defaultValue,
  }) async {
    return await storage.tryGetList(key) ?? defaultValue;
  }

  @override
  Future<List<Map<String, dynamic>>> get(
    String key,
    ListStorageContract storage,
    List<Map<String, dynamic>> defaultValue,
  ) async {
    return await storage.getList(key, defaultValue);
  }

  @override
  Future<void> set(
    String key,
    ListStorageContract storage,
    List<Map<String, dynamic>> value,
  ) async {
    await storage.setList(key, value);
  }

  @override
  Future<void> remove(String key, ListStorageContract storage) async {
    await storage.remove(key);
  }
}
