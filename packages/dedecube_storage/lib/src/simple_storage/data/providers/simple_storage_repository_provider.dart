import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_service_provider.dart';
import 'package:dedecube_storage/src/simple_storage/data/repositories/simple_storage_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'simple_storage_repository_provider.g.dart';

@Riverpod(keepAlive: true)
SimpleStorageRepository simpleStorageRepository(
  Ref ref,
) {
  return SimpleStorageRepository(
    simpleStorageService: ref.watch(simpleStorageServiceProvider),
  );
}
