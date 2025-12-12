import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';

/// Data handler contract used as template to define the behavior of a data handler.
///
/// A data handler is responsible for managing the storage and retrieval of data
/// of type [T] using a storage implementation [S] that conforms to [StorageContract].
///
/// Type parameters:
/// * [T] - The type of data being handled
/// * [S] - The type of storage implementation extending [StorageContract]
abstract class DataHandlerContract<T, S extends StorageContract> {
  Future<T?> tryGet(String key, S storage, {T? defaultValue});

  Future<T> get(String key, S storage, T defaultValue);

  Future<void> set(String key, S storage, T value);

  Future<void> remove(String key, S storage);
}
