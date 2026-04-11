// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'post_media_dto.freezed.dart';
part 'post_media_dto.g.dart';

@freezed
sealed class PostMediaDto with _$PostMediaDto {
  const factory PostMediaDto({
    required String id,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'media_type') required String mediaType,
    @JsonKey(name: 'media_url') required String mediaUrl,
    @JsonKey(name: 'sort_order') required int sortOrder,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'duration_seconds') double? durationSeconds,
  }) = _PostMediaDto;

  factory PostMediaDto.fromJson(Map<String, dynamic> json) =>
      _$PostMediaDtoFromJson(json);
}
