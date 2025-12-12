import 'package:dedecube_storage/src/storage/contracts/data_handler_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/string_storage_contract.dart';

class StringHandler extends DataHandlerContract<String, StringStorageContract> {
  @override
  Future<String?> tryGet(
    String key,
    StringStorageContract storage, {
    String? defaultValue,
  }) async {
    return await storage.tryGetString(key) ?? defaultValue;
  }

  @override
  Future<String> get(
    String key,
    StringStorageContract storage,
    String defaultValue,
  ) async {
    return await storage.getString(key, defaultValue);
  }

  @override
  Future<void> set(
    String key,
    StringStorageContract storage,
    String value,
  ) async {
    await storage.setString(key, value);
  }

  @override
  Future<void> remove(String key, StringStorageContract storage) async {
    await storage.remove(key);
  }
}
