import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/get_int_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_int_provider.g.dart';

/// Retrieves an integer storage variable.
///
/// Creates an instance of [`GetIntUseCase`](lib/secure_storage/domain/use_cases/get_int_use_case.dart)
/// and executes it to obtain the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [defaultValue]: The default value if the key is not found.
///
/// Returns the integer value associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
Future<int?> getInt(
  Ref ref,
  String key, {
  int? defaultValue,
}) async {
  final getIntUseCase = GetIntUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return await getIntUseCase.execute();
}
