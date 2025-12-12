import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_repository_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/use_cases/remove_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remove_provider.g.dart';

/// Removes a storage variable.
///
/// Creates an instance of [`RemoveUseCase`](lib/simple_storage/domain/use_cases/remove_use_case.dart)
/// and executes it to remove the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key to remove.
@Riverpod(keepAlive: false)
Future<bool> remove(
  Ref ref,
  String key,
) async {
  final removeUseCase = RemoveUseCase(
    repository: ref.watch(simpleStorageRepositoryProvider),
    key: key,
  );

  return await removeUseCase.execute();
}
