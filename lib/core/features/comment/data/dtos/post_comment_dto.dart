// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'post_comment_dto.freezed.dart';
part 'post_comment_dto.g.dart';

/// DTO for post comments from the database.
@freezed
sealed class PostCommentDto with _$PostCommentDto {
  const factory PostCommentDto({
    required String id,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'author_username') required String authorUsername,
    @JsonKey(name: 'author_avatar_url') String? authorAvatarUrl,
    required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'deleted_at') String? deletedAt,
  }) = _PostCommentDto;

  factory PostCommentDto.fromJson(Map<String, dynamic> json) =>
      _$PostCommentDtoFromJson(json);
}
