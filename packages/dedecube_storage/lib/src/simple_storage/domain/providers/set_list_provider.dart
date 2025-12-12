import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_repository_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/use_cases/set_list_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_list_provider.g.dart';

/// Sets a list storage variable.
///
/// Creates an instance of [SetListUseCase] and executes it to set the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key.
/// - [list]: The list of objects ([List<Map<String, dynamic>>]) to store.
@Riverpod(keepAlive: false)
Future<bool> setList(
  Ref ref,
  String key,
  List<Map<String, dynamic>> list,
) async {
  final setListUseCase = SetListUseCase(
    repository: ref.watch(simpleStorageRepositoryProvider),
    key: key,
    list: list,
  );
  return await setListUseCase.execute();
}
