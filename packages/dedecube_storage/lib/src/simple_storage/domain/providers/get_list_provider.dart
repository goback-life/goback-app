import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_repository_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/use_cases/get_list_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_list_provider.g.dart';

/// Retrieves a list storage variable.
///
/// Creates an instance of [GetListUseCase] and executes it to obtain the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [defaultValue]: The default value if the key is not found or decoding fails.
///
/// Returns the list of objects ([List<Map<String, dynamic>>]?) associated with [key] or [defaultValue] if not found.
@Riverpod(keepAlive: false)
Future<List<Map<String, dynamic>>?> getList(
  Ref ref,
  String key, {
  List<Map<String, dynamic>>? defaultValue,
}) async {
  final getListUseCase = GetListUseCase(
    repository: ref.watch(simpleStorageRepositoryProvider),
    key: key,
    defaultValue: defaultValue,
  );

  return await getListUseCase.execute();
}
