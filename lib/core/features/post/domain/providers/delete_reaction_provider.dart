import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/use_cases/delete_reaction_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_reaction_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<void>> deleteReaction(
  Ref ref, {
  required String reactionId,
}) async {
  final useCase = DeleteReactionUseCase(
    repository: ref.watch(postRepositoryProvider),
  ).withReactionData(reactionId: reactionId);

  return useCase.execute();
}
