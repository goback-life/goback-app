import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/secure_storage/data/providers/secure_storage_repository_provider.dart';
import 'package:dedecube_storage/src/secure_storage/domain/use_cases/clear_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clear_provider.g.dart';

/// Clears all storage variables.
///
/// Creates an instance of [`ClearUseCase`](lib/secure_storage/domain/use_cases/clear_use_case.dart)
/// and executes it to clear all storage variables.
///
/// - [ref]: The provider reference.
@Riverpod(keepAlive: false)
Future<void> clear(
  Ref ref,
) async {
  final clearUseCase = ClearUseCase(
    repository: ref.watch(secureStorageRepositoryProvider),
  );

  return await clearUseCase.execute();
}
