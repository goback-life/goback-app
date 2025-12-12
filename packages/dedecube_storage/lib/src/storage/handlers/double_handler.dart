import 'package:dedecube_storage/src/storage/contracts/data_handler_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/double_storage_contract.dart';

class DoubleHandler extends DataHandlerContract<double, DoubleStorageContract> {
  @override
  Future<double?> tryGet(
    String key,
    DoubleStorageContract storage, {
    double? defaultValue,
  }) async {
    return await storage.tryGetDouble(key) ?? defaultValue;
  }

  @override
  Future<double> get(
    String key,
    DoubleStorageContract storage,
    double defaultValue,
  ) async {
    return await storage.getDouble(key, defaultValue);
  }

  @override
  Future<void> set(
    String key,
    DoubleStorageContract storage,
    double value,
  ) async {
    await storage.setDouble(key, value);
  }

  @override
  Future<void> remove(String key, DoubleStorageContract storage) async {
    await storage.remove(key);
  }
}
