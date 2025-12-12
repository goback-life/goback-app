import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/set_double_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_double_provider.g.dart';

/// Sets a double storage variable.
///
/// Creates an instance of [`SetDoubleUseCase`](lib/secure_storage/domain/use_cases/set_double_use_case.dart)
/// and executes it to set the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [value]: The double value to set.
@Riverpod(keepAlive: false)
Future<void> setDouble(
  Ref ref,
  String key,
  double value,
) async {
  final setDoubleUseCase = SetDoubleUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
    value: value,
  );

  return await setDoubleUseCase.execute();
}
