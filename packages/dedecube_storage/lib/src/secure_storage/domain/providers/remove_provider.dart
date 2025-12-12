import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/remove_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remove_provider.g.dart';

/// Removes a storage variable.
///
/// Creates an instance of [`RemoveUseCase`](lib/secure_storage/domain/use_cases/remove_use_case.dart)
/// and executes it to remove the storage variable.
///
/// - [ref]: The provider reference.
/// - [key]: The storage variable key to remove.
@Riverpod(keepAlive: false)
Future<void> remove(
  Ref ref,
  String key,
) async {
  final removeUseCase = RemoveUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
    key: key,
  );

  return await removeUseCase.execute();
}
