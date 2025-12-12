// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'post_reaction_dto.freezed.dart';
part 'post_reaction_dto.g.dart';

@freezed
sealed class PostReactionDto with _$PostReactionDto {
  const factory PostReactionDto({
    required String id,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'user_id') required String userId,
    required String reaction,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _PostReactionDto;

  factory PostReactionDto.fromJson(Map<String, dynamic> json) =>
      _$PostReactionDtoFromJson(json);
}
