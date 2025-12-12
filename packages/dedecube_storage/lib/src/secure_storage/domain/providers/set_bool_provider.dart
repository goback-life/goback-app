import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/set_bool_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_bool_provider.g.dart';

/// Sets a boolean storage variable.
///
/// Creates an instance of [`SetBoolUseCase`](lib/secure_storage/domain/use_cases/set_bool_use_case.dart)
/// and executes it to set the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [value]: The boolean value to set.
@Riverpod(keepAlive: false)
Future<void> setBool(
  Ref ref,
  String key,
  bool value,
) async {
  final setBoolUseCase = SetBoolUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
    value: value,
  );

  return await setBoolUseCase.execute();
}
