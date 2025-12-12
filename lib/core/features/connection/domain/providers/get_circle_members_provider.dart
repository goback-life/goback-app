import 'package:cloudless/core/features/connection/data/providers/connection_repository_provider.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/core/features/connection/domain/use_cases/get_circle_members_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_circle_members_provider.g.dart';

/// Fetches the list of circle members.
///
/// This provider auto-disposes when no longer watched.
/// For real-time updates, consumers should invalidate this provider
/// or use polling in the UI layer.
@Riverpod(keepAlive: false)
Future<Result<List<ConnectionMemberModel>>> getCircleMembers(Ref ref) async {
  final useCase = GetCircleMembersUseCase(
    repository: ref.watch(connectionRepositoryProvider),
  );

  return await useCase.execute();
}
