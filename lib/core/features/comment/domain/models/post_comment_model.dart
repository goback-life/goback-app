import 'package:dedecube_core/dedecube_core.dart';

part 'post_comment_model.freezed.dart';

/// Domain model representing a comment on a post.
@freezed
sealed class PostCommentModel with _$PostCommentModel {
  const factory PostCommentModel({
    required String id,
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorAvatarUrl,
    required String content,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _PostCommentModel;
}
