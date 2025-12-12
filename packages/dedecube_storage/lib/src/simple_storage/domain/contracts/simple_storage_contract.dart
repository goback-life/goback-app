import 'package:dedecube_storage/src/storage/contracts/storage/bool_storage_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/double_storage_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/int_storage_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/list_storage_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/object_storage_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/storage_contract.dart';
import 'package:dedecube_storage/src/storage/contracts/storage/string_storage_contract.dart';

/// A contract for the Storage class, defining the required methods and properties.
abstract class SimpleStorageContract extends StorageContract
    implements
        BoolStorageContract,
        DoubleStorageContract,
        IntStorageContract,
        StringStorageContract,
        ObjectStorageContract,
        ListStorageContract {
  /// Initializes the environment with the required providers.
  Future<void> initialize();
}
