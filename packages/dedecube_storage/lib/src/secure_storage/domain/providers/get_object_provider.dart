import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/get_object_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_object_provider.g.dart';

/// Retrieves an object storage variable.
///
/// Creates an instance of [GetObjectUseCase] and executes it to obtain the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [defaultValue]: The default value if the key is not found or decoding fails.
///
/// Returns the object ([Map<String, dynamic>>?) associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
Future<Map<String, dynamic>?> getObject(
  Ref ref,
  String key, {
  Map<String, dynamic>? defaultValue,
}) async {
  final getObjectUseCase = GetObjectUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );
  return await getObjectUseCase.execute();
}
