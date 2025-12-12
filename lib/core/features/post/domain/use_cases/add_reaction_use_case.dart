import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class AddReactionUseCase implements UseCaseContract<Result<PostReactionModel>> {
  AddReactionUseCase({required this.repository});

  final PostRepositoryContract repository;

  String? _postId;
  String? _userId;
  String? _reaction;

  AddReactionUseCase withReactionData({
    required String postId,
    required String userId,
    required String reaction,
  }) {
    return AddReactionUseCase(repository: repository)
      .._postId = postId
      .._userId = userId
      .._reaction = reaction;
  }

  @override
  Future<Result<PostReactionModel>> execute() async {
    final postId = _postId;
    final userId = _userId;
    final reaction = _reaction;

    if (postId == null || postId.isEmpty) {
      logger.info('Post ID is required for adding reaction');
      return Result.failure(Exception('Post ID is required'));
    }

    if (userId == null || userId.isEmpty) {
      logger.info('User ID is required for adding reaction');
      return Result.failure(Exception('User ID is required'));
    }

    if (reaction == null || reaction.isEmpty) {
      logger.info('Reaction is required');
      return Result.failure(Exception('Reaction is required'));
    }

    return await repository.addReaction(
      postId: postId,
      userId: userId,
      reaction: reaction,
    );
  }
}
