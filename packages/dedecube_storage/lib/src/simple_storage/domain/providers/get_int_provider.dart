import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_repository_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/use_cases/get_int_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_int_provider.g.dart';

/// Retrieves an integer storage variable.
///
/// Creates an instance of [`GetIntUseCase`](lib/simple_storage/domain/use_cases/get_int_use_case.dart)
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
    repository: ref.watch(simpleStorageRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return getIntUseCase.execute();
}
