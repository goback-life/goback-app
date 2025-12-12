import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_repository_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/use_cases/get_bool_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_bool_provider.g.dart';

/// Retrieves a boolean storage variable.
///
/// Creates an instance of [`GetBoolUseCase`](lib/simple_storage/domain/use_cases/get_bool_use_case.dart)
/// and executes it to obtain the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [defaultValue]: The default value if the key is not found.
///
/// Returns the boolean value associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
Future<bool?> getBool(
  Ref ref,
  String key, {
  bool? defaultValue,
}) async {
  final getBoolUseCase = GetBoolUseCase(
    repository: ref.watch(simpleStorageRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return getBoolUseCase.execute();
}
