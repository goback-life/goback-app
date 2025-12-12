// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

@freezed
sealed class PostDto with _$PostDto {
  const factory PostDto({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'content_type') required String contentType,
    @JsonKey(name: 'thumbnail_url') required String thumbnailUrl,
    @JsonKey(name: 'thumbnail_width') required int thumbnailWidth,
    @JsonKey(name: 'thumbnail_height') required int thumbnailHeight,
    @JsonKey(name: 'content_date') required String contentDate,
    required String status,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'published_at') required String publishedAt,
    @JsonKey(name: 'published_timezone') required String publishedTimezone,
    @JsonKey(name: 'deleted_at') String? deletedAt,
    @JsonKey(name: 'parent_id') String? parentId,
    String? description,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
}
