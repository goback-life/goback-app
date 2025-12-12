import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/data/providers/environment_repository_provider.dart';
import 'package:dedecube_environment/src/domain/use_cases/initialize_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initialize_provider.g.dart';

@Riverpod(keepAlive: false)
Future<void> initialize(
  Ref ref,
  String filename,
) async {
  final useCase = InitializeUseCase(
    repository: ref.watch(environmentRepositoryProvider),
    filename: filename,
  );

  return useCase.execute();
}
