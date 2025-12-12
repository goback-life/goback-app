import 'package:cloudless/core/features/connection/data/providers/connection_repository_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/connection/domain/use_cases/remove_connection_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remove_connection_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<bool>> removeConnection(Ref ref, String userId) async {
  final useCase = RemoveConnectionUseCase(
    repository: ref.watch(connectionRepositoryProvider),
    userId: userId,
  );

  final result = await useCase.execute();

  // Invalidate circle members to refresh the list after removal
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
