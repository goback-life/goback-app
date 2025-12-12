import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/models/feed_response_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_reaction_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_report_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class PostRepositoryContract {
  Future<Result<PostModel>> createPost(PostDataModel postData);
  Future<Result<PostModel>> updatePost(PostDataModel postData);
  Future<Result<FeedResponseModel>> getFeedPosts({
    required String userId,
    required DateTime targetDate,
    int pageSize = 15,
    int pageOffset = 0,
    DateTime? cursorBefore,
    DateTime? cursorAfter,
  });

  Future<Result<FeedPostModel>> getPostById({required String postId});

  Future<Result<void>> deletePost({
    required String postId,
    required String authorId,
  });
  Future<Result<void>> hidePost({
    required String postId,
    required String userId,
  });
  Future<Result<PostReportModel>> reportPost({
    required String postId,
    required String userId,
    required String reason,
  });

  Future<Result<List<PostReactionModel>>> getPostReactions({
    required String postId,
  });

  Future<Result<PostReactionModel>> addReaction({
    required String postId,
    required String userId,
    required String reaction,
  });

  Future<Result<void>> deleteReaction({required String reactionId});
}
