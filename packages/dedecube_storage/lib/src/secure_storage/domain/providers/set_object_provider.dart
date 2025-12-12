import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/set_object_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_object_provider.g.dart';

/// Sets an object storage variable.
///
/// Creates an instance of [SetObjectUseCase] and executes it to set the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [object]: The object to store (as a Map).
@Riverpod(keepAlive: false)
Future<void> setObject(
  Ref ref,
  String key,
  Map<String, dynamic> object,
) async {
  final setObjectUseCase = SetObjectUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
    object: object,
  );

  return await setObjectUseCase.execute();
}
