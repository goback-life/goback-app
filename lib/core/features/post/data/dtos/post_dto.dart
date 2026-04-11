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
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'published_at') String? publishedAt,
    @JsonKey(name: 'published_timezone') String? publishedTimezone,

    /// Reference to lockout_sessions table if this is a lockout post
    @JsonKey(name: 'lockout_id') String? lockoutId,

    /// When this post was saved to calendar (null if not saved)
    @JsonKey(name: 'calendar_saved_at') String? calendarSavedAt,

    /// Excluded user IDs as UUID[] array
    @JsonKey(name: 'excluded_user_ids') List<String>? excludedUserIds,
    String? description,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
}
