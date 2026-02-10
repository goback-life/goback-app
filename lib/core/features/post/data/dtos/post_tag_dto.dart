// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'post_tag_dto.freezed.dart';
part 'post_tag_dto.g.dart';

/// Enum for tag types
enum PostTagType {
  participant, // Auto-tagged from lockout participants
  mention,     // Manual @mention in description/comments
}

@freezed
sealed class PostTagDto with _$PostTagDto {
  const factory PostTagDto({
    required String id,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'tagged_user_id') required String taggedUserId,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'tag_type') @Default('mention') String tagType,
    String? username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _PostTagDto;

  factory PostTagDto.fromJson(Map<String, dynamic> json) =>
      _$PostTagDtoFromJson(json);
}
