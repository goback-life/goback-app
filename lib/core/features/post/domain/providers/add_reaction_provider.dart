import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/features/post/domain/use_cases/add_reaction_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_reaction_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<PostReactionModel>> addReaction(
  Ref ref, {
  required String postId,
  required String userId,
  required String reaction,
}) async {
  final useCase = AddReactionUseCase(
    repository: ref.watch(postRepositoryProvider),
  ).withReactionData(postId: postId, userId: userId, reaction: reaction);

  return useCase.execute();
}
