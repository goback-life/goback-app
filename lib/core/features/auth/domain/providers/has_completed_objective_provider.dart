import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/has_completed_objective_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'has_completed_objective_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> hasCompletedObjective(Ref ref) {
  final useCase = HasCompletedObjectiveUseCase(
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
