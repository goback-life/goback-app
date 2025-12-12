import 'package:dedecube_storage/src/storage.dart';
import 'package:dedecube_storage/src/storage/contracts/data_handler_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';
import 'package:dedecube_storage/src/storage/enums/storage_type.dart';
import 'package:dedecube_storage/src/storage/exceptions/unsupported_storage_type_exception.dart';
import 'package:dedecube_storage/src/storage/handlers/bool_handler.dart';
import 'package:dedecube_storage/src/storage/handlers/double_handler.dart';
import 'package:dedecube_storage/src/storage/handlers/int_handler.dart';
import 'package:dedecube_storage/src/storage/handlers/list_handler.dart';
import 'package:dedecube_storage/src/storage/handlers/object_handler.dart';
import 'package:dedecube_storage/src/storage/handlers/string_handler.dart';

/// A base class for objects that can be stored persistently.
///
/// The type parameter [T] represents the type of the storable object.
abstract class Storable<T> {
  const Storable();

  String get key;

  StorageType get storageType;

  StorageContract get _storage => _getStorage();

  DataHandlerContract<T, StorageContract> get _handler => _createHandler();

  /// Attempts to retrieve a value from storage, returning a [defaultValue] if not found.
  ///
  /// Returns a [Future] that completes with either:
  /// - The stored value of type [T] if found
  /// - The provided [defaultValue] if the value is not found
  /// - null if no [defaultValue] is provided and the value is not found
  Future<T?> tryGet({T? defaultValue}) async {
    return await _handler.tryGet(key, _storage, defaultValue: defaultValue);
  }

  /// Retrieves a value from storage.
  ///
  /// If the value doesn't exist in storage, returns the [defaultValue].
  ///
  /// Parameters:
  ///   * [defaultValue]: The default value to return if no value is found in storage.
  Future<T> get({required T defaultValue}) async {
    return await _handler.get(key, _storage, defaultValue);
  }

  /// Sets a new value in the storage.
  Future<void> set(T value) async {
    await _handler.set(key, _storage, value);
  }

  /// This method deletes the storable entity from its storage location.
  Future<void> remove() async {
    await _handler.remove(key, _storage);
  }

  StorageContract _getStorage() {
    switch (storageType) {
      case StorageType.secure:
        return secureStorage;
      case StorageType.simple:
        return simpleStorage;
    }
  }

  DataHandlerContract<T, StorageContract> _createHandler() {
    final handlerMap = <Type, DataHandlerContract>{
      bool: BoolHandler(),
      double: DoubleHandler(),
      int: IntHandler(),
      String: StringHandler(),
      Map: ObjectHandler(),
      List<Map<String, dynamic>>: ListHandler(),
    };

    final handler = handlerMap[T];
    if (handler != null) {
      return handler as DataHandlerContract<T, StorageContract>;
    }

    throw UnsupportedStorageTypeException('Type $T not supported.');
  }
}
