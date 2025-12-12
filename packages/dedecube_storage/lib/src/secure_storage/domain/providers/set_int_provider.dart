import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/set_int_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_int_provider.g.dart';

/// Sets an integer storage variable.
///
/// Creates an instance of [`SetIntUseCase`](lib/secure_storage/domain/use_cases/set_int_use_case.dart)
/// and executes it to set the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [value]: The integer value to set.
@Riverpod(keepAlive: false)
Future<void> setInt(
  Ref ref,
  String key,
  int value,
) async {
  final setIntUseCase = SetIntUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
    value: value,
  );

  return await setIntUseCase.execute();
}
