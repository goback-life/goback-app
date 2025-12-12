import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/services/simple_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'simple_storage_service_provider.g.dart';

@Riverpod(keepAlive: true)
SimpleStorageService simpleStorageService(Ref ref) {
  return SimpleStorageService(
    ref,
  );
}
