import 'package:cloudless/core/features/comment/data/providers/comment_service_provider.dart';
import 'package:cloudless/core/features/comment/domain/providers/get_post_comments_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_comment_provider.g.dart';

/// Provider for deleting a comment.
@riverpod
class DeleteComment extends _$DeleteComment {
  @override
  Future<Result<void>?> build() async {
    return null;
  }

  /// Deletes a comment.
  Future<Result<void>> delete({
    required String commentId,
    required String postId,
  }) async {
    state = const AsyncLoading();

    final service = ref.read(commentServiceProvider);
    final result = await service.deleteComment(commentId: commentId);

    state = AsyncData(result);

    // Refresh the comments list for this post on success
    result.fold(
      (_) => ref.invalidate(getPostCommentsProvider(postId)),
      (_) {},
    );

    return result;
  }
}
