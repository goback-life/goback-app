import 'package:cloudless/core/features/connection/data/providers/connection_repository_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/use_cases/join_circle_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'join_circle_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> joinCircle(Ref ref, String inviteCode) async {
  final useCase = JoinCircleUseCase(
    repository: ref.watch(connectionRepositoryProvider),
    inviteCode: inviteCode,
  );

  final result = await useCase.execute();

  // Invalidate circle members to refresh the list after joining
  result.fold(
    (success) {
      if (success) {
        ref.invalidate(getCircleMembersProvider);
      }
    },
    (_) {}, // Do nothing on error
  );

  return result;
}
