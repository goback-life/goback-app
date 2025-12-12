import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_service_provider.dart';
import 'package:dedecube_storage/src/secure_storage/data/repositories/secure_storage_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_repository_provider.g.dart';

@Riverpod(keepAlive: true)
SecureStorageRepository secureStorageRepository(
  Ref ref,
) {
  return SecureStorageRepository(
    secureStorageService: ref.watch(secureStorageServiceProvider),
  );
}
