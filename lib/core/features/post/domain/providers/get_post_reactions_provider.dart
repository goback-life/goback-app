import 'package:cloudless/core/features/post/data/providers/post_repository_provider.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/features/post/domain/use_cases/get_post_reactions_use_case.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_post_reactions_provider.g.dart';

@Riverpod(keepAlive: false)
Future<Result<List<PostReactionModel>>> getPostReactions(
  Ref ref, {
  required String postId,
}) async {
  final useCase = GetPostReactionsUseCase(
    repository: ref.watch(postRepositoryProvider),
  ).withPostId(postId);

  return useCase.execute();
}
