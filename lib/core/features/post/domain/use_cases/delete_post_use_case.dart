import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class DeletePostUseCase implements UseCaseContract<Result<void>> {
  DeletePostUseCase({required this.repository});

  final PostRepositoryContract repository;

  String? _postId;
  String? _authorId;

  DeletePostUseCase withPostData({
    required String postId,
    required String authorId,
  }) {
    return DeletePostUseCase(repository: repository)
      .._postId = postId
      .._authorId = authorId;
  }

  @override
  Future<Result<void>> execute() async {
    final postId = _postId;
    final authorId = _authorId;

    if (postId == null || postId.isEmpty) {
      logger.info('Post ID is required for deletion');
      return Result.failure(Exception('Post ID is required for deletion'));
    }

    if (authorId == null || authorId.isEmpty) {
      logger.info('Author ID is required for deletion');
      return Result.failure(Exception('Author ID is required for deletion'));
    }

    return await repository.deletePost(postId: postId, authorId: authorId);
  }
}
