import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/comment/domain/models/post_comment_model.dart';
import 'package:cloudless/core/features/comment/domain/providers/create_comment_provider.dart';
import 'package:cloudless/core/features/comment/domain/providers/delete_comment_provider.dart';
import 'package:cloudless/core/features/comment/domain/providers/get_post_comments_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

const int kMaxCommentsPerUserPerPost = 10;

typedef PostCommentsResult = ({
  AsyncValue<Result<List<PostCommentModel>>> comments,
  int commentCount,
  int userCommentCount,
  bool canAddMore,
  bool isLoading,
  bool isSubmitting,
  Future<void> Function(String content, {List<String>? mentionedUserIds})
  addComment,
  Future<void> Function(String commentId) deleteComment,
  bool Function(PostCommentModel comment) isOwnComment,
  VoidCallback refresh,
});

PostCommentsResult usePostComments(WidgetRef ref, String postId) {
  final comments = ref.watch(getPostCommentsProvider(postId));
  final currentUserAsync = ref.watch(getCurrentUserProvider);
  final isSubmitting = useState<bool>(false);
  final optimisticCount = useState<int?>(null);

  final serverCount =
      comments.whenOrNull(
        data: (r) => r.fold((list) => list.length, (_) => 0),
      ) ??
      0;
  final displayCount = optimisticCount.value ?? serverCount;

  final currentUserId = currentUserAsync.whenOrNull(
    data: (result) => result.fold((user) => user.id, (_) => null),
  );

  // Count how many comments the current user has on this post
  final userCommentCount =
      comments.whenOrNull(
        data: (r) => r.fold(
          (list) => currentUserId != null
              ? list.where((c) => c.authorId == currentUserId).length
              : 0,
          (_) => 0,
        ),
      ) ??
      0;

  final canAddMore = userCommentCount < kMaxCommentsPerUserPerPost;

  Future<void> addComment(
    String content, {
    List<String>? mentionedUserIds,
  }) async {
    if (isSubmitting.value || content.trim().isEmpty) return;
    isSubmitting.value = true;

    optimisticCount.value = displayCount + 1;

    final result = await ref
        .read(createCommentProvider.notifier)
        .create(
          postId: postId,
          content: content.trim(),
          mentionedUserIds: mentionedUserIds,
        );

    result.fold((_) => optimisticCount.value = null, (error) {
      optimisticCount.value = null;
      logger.error('Failed to add comment', exception: error);
    });
    isSubmitting.value = false;
  }

  Future<void> deleteComment(String commentId) async {
    optimisticCount.value = (displayCount - 1).clamp(0, displayCount);

    final result = await ref
        .read(deleteCommentProvider.notifier)
        .delete(commentId: commentId, postId: postId);

    result.fold((_) => optimisticCount.value = null, (error) {
      optimisticCount.value = null;
      logger.error('Failed to delete comment', exception: error);
    });
  }

  bool isOwnComment(PostCommentModel comment) {
    return currentUserId != null && comment.authorId == currentUserId;
  }

  void refresh() {
    ref.invalidate(getPostCommentsProvider(postId));
  }

  return (
    comments: comments,
    commentCount: displayCount,
    userCommentCount: userCommentCount,
    canAddMore: canAddMore,
    isLoading: comments.isLoading,
    isSubmitting: isSubmitting.value,
    addComment: addComment,
    deleteComment: deleteComment,
    isOwnComment: isOwnComment,
    refresh: refresh,
  );
}
