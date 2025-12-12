import 'package:dedecube_storage/src/storage/contracts/data_handler_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/object_storage_contract.dart';

class ObjectHandler
    extends DataHandlerContract<Map<String, dynamic>, ObjectStorageContract> {
  @override
  Future<Map<String, dynamic>?> tryGet(
    String key,
    ObjectStorageContract storage, {
    Map<String, dynamic>? defaultValue,
  }) async {
    return await storage.tryGetObject(key) ?? defaultValue;
  }

  @override
  Future<Map<String, dynamic>> get(
    String key,
    ObjectStorageContract storage,
    Map<String, dynamic> defaultValue,
  ) async {
    return await storage.getObject(key, defaultValue);
  }

  @override
  Future<void> set(
    String key,
    ObjectStorageContract storage,
    Map<String, dynamic> value,
  ) async {
    await storage.setObject(key, value);
  }

  @override
  Future<void> remove(String key, ObjectStorageContract storage) async {
    await storage.remove(key);
  }
}
