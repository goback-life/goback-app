import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class HidePostUseCase implements UseCaseContract<Result<void>> {
  HidePostUseCase({required this.repository});

  final PostRepositoryContract repository;

  String? _postId;
  String? _userId;

  HidePostUseCase withPostData({
    required String postId,
    required String userId,
  }) {
    return HidePostUseCase(repository: repository)
      .._postId = postId
      .._userId = userId;
  }

  @override
  Future<Result<void>> execute() async {
    final postId = _postId;
    final userId = _userId;

    if (postId == null || postId.isEmpty) {
      logger.info('Post ID is required for hiding');
      return Result.failure(Exception('Post ID is required for hiding'));
    }

    if (userId == null || userId.isEmpty) {
      logger.info('User ID is required for hiding');
      return Result.failure(Exception('User ID is required for hiding'));
    }

    return await repository.hidePost(postId: postId, userId: userId);
  }
}
