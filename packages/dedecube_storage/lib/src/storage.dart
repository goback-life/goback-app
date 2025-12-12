import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage.dart';
import 'package:dedecube_storage/src/secure_storage/domain/contracts/secure_storage_contract.dart';
import 'package:dedecube_storage/src/simple_storage.dart';
import 'package:dedecube_storage/src/simple_storage/domain/contracts/simple_storage_contract.dart';

/// Storage class to manage dependency injection and initialization of storage services.
class Storage {
  static Future<void> initialize() async {
    GetIt.I.registerSingleton<SimpleStorageContract>(
      SimpleStorage(),
    );
    GetIt.I.registerSingleton<SecureStorageContract>(
      SecureStorage(),
    );

    await simpleStorage.initialize();
  }
}

SimpleStorageContract get simpleStorage => GetIt.I<SimpleStorageContract>();

SecureStorageContract get secureStorage => GetIt.I<SecureStorageContract>();
