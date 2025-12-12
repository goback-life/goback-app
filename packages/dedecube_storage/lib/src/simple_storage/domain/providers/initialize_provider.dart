import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_storage/src/simple_storage/data/providers/simple_storage_repository_provider.dart';
import 'package:dedecube_storage/src/simple_storage/domain/use_cases/initialize_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initialize_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> initialize(
  Ref ref,
) async {
  final useCase = InitializeUseCase(
    repository: ref.watch(simpleStorageRepositoryProvider),
  );

  return useCase.execute();
}
