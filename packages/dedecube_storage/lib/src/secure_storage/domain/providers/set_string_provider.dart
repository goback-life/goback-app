import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/set_string_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_string_provider.g.dart';

/// Sets a string storage variable.
///
/// Creates an instance of [`SetStringUseCase`](lib/secure_storage/domain/use_cases/set_string_use_case.dart)
/// and executes it to set the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [value]: The string value to set.
@Riverpod(keepAlive: false)
Future<void> setString(
  Ref ref,
  String key,
  String value,
) async {
  final setStringUseCase = SetStringUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
    value: value,
  );

  return await setStringUseCase.execute();
}
