import 'package:cloudless/core/features/comment/data/dtos/post_comment_dto.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Contract for comment service operations.
abstract class CommentServiceContract {
  /// Gets all comments for a post.
  ///
  /// Returns comments ordered by creation date (oldest first).
  FutureResult<List<PostCommentDto>> getPostComments({
    required String postId,
    int limit = 50,
    DateTime? cursor,
  });

  /// Creates a new comment on a post.
  FutureResult<PostCommentDto> createComment({
    required String postId,
    required String content,
  });

  /// Deletes a comment (soft delete).
  ///
  /// Only the comment author can delete their own comments.
  FutureResult<void> deleteComment({required String commentId});

  /// Gets the count of comments for a post.
  FutureResult<int> getCommentCount({required String postId});
}
