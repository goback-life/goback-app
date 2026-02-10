import 'package:cloudless/core/features/comment/data/mappers/comment_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/comment/data/providers/comment_service_provider.dart';
import 'package:cloudless/core/features/comment/domain/models/post_comment_model.dart';
import 'package:cloudless/core/features/comment/domain/providers/get_post_comments_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_comment_provider.g.dart';

/// Provider for creating a comment on a post.
@riverpod
class CreateComment extends _$CreateComment {
  final _mapper = CommentDtoToModelMapper();

  @override
  Future<Result<PostCommentModel>?> build() async {
    return null;
  }

  /// Creates a new comment on a post.
  ///
  /// If [mentionedUserIds] is provided, creates mention records for those users.
  Future<Result<PostCommentModel>> create({
    required String postId,
    required String content,
    List<String>? mentionedUserIds,
  }) async {
    state = const AsyncLoading();

    final service = ref.read(commentServiceProvider);
    final result = await service.createComment(
      postId: postId,
      content: content,
      mentionedUserIds: mentionedUserIds,
    );

    final mappedResult = result.fold(
      (dto) => Result.success(_mapper.mapDto(dto)),
      (error) => Result<PostCommentModel>.failure(error),
    );

    state = AsyncData(mappedResult);

    // Refresh the comments list for this post on success
    mappedResult.fold(
      (_) => ref.invalidate(getPostCommentsProvider(postId)),
      (_) {},
    );

    return mappedResult;
  }
}
