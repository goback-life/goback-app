import 'package:cloudless/core/features/post/domain/contracts/post_repository_contract.dart';
import 'package:cloudless/core/features/post/domain/models/feed_response_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class GetFeedPostsUseCase {
  const GetFeedPostsUseCase({required this.repository});

  final PostRepositoryContract repository;

  Future<Result<FeedResponseModel>> execute({
    required String userId,
    required DateTime targetDate,
    int pageSize = 15,
    int pageOffset = 0,
    DateTime? cursorBefore,
    DateTime? cursorAfter,
  }) async {
    return await repository.getFeedPosts(
      userId: userId,
      targetDate: targetDate,
      pageSize: pageSize,
      pageOffset: pageOffset,
      cursorBefore: cursorBefore,
      cursorAfter: cursorAfter,
    );
  }
}
