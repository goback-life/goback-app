// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'post_exclusion_dto.freezed.dart';
part 'post_exclusion_dto.g.dart';

@freezed
sealed class PostExclusionDto with _$PostExclusionDto {
  const factory PostExclusionDto({
    required String id,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'excluded_user_id') required String excludedUserId,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _PostExclusionDto;

  factory PostExclusionDto.fromJson(Map<String, dynamic> json) =>
      _$PostExclusionDtoFromJson(json);
}
