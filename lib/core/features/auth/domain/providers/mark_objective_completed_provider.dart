import 'package:cloudless/core/features/auth/data/providers/auth_repository_provider.dart';
import 'package:cloudless/core/features/auth/domain/use_cases/mark_objective_completed_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mark_objective_completed_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> markObjectiveCompleted(Ref ref) {
  final useCase = MarkObjectiveCompletedUseCase(
    repository: ref.watch(authRepositoryProvider),
  );

  return useCase.execute();
}
