import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class GetPostReactionsUseCase
    implements UseCaseContract<Result<List<PostReactionModel>>> {
  GetPostReactionsUseCase({required this.repository});

  final PostRepositoryContract repository;

  String? _postId;

  GetPostReactionsUseCase withPostId(String postId) {
    return GetPostReactionsUseCase(repository: repository).._postId = postId;
  }

  @override
  Future<Result<List<PostReactionModel>>> execute() async {
    final postId = _postId;

    if (postId == null || postId.isEmpty) {
      logger.info('Post ID is required for getting reactions');
      return Result.failure(Exception('Post ID is required'));
    }

    return await repository.getPostReactions(postId: postId);
  }
}
