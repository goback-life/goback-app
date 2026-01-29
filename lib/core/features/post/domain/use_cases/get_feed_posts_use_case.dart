import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/models/feed_response_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetFeedPostsUseCase {
  const GetFeedPostsUseCase({required this.repository});

  final PostRepositoryContract repository;

  Future<Result<FeedResponseModel>> execute({
    required String userId,
    int pageSize = 15,
    DateTime? cursor,
  }) async {
    return await repository.getFeedPosts(
      userId: userId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }
}
