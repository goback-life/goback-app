import 'package:cloudless/core/features/comment/data/mappers/comment_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/comment/data/providers/comment_service_provider.dart';
import 'package:cloudless/core/features/comment/domain/models/post_comment_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_post_comments_provider.g.dart';

/// Provider that fetches comments for a post.
///
/// Auto-disposes when no longer watched.
@riverpod
class GetPostComments extends _$GetPostComments {
  final _mapper = CommentDtoToModelMapper();

  @override
  Future<Result<List<PostCommentModel>>> build(String postId) async {
    final service = ref.watch(commentServiceProvider);
    final result = await service.getPostComments(postId: postId);

    return result.fold(
      (dtos) => Result.success(_mapper.mapDtoList(dtos)),
      (error) => Result.failure(error),
    );
  }

  /// Force refresh the comments list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final postId = this.postId;
    state = AsyncData(await build(postId));
  }
}
