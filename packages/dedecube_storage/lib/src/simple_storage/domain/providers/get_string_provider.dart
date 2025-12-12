import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_repository_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/use_cases/get_string_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_string_provider.g.dart';

/// Retrieves a string storage variable.
///
/// Creates an instance of [`GetStringUseCase`](lib/simple_storage/domain/use_cases/get_string_use_case.dart)
/// and executes it to obtain the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [defaultValue]: The default value if the key is not found.
///
/// Returns the string value associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
Future<String?> getString(
  Ref ref,
  String key, {
  String? defaultValue,
}) async {
  final getStringUseCase = GetStringUseCase(
    repository: ref.watch(simpleStorageRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return getStringUseCase.execute();
}
