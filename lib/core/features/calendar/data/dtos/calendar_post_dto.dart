// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'calendar_post_dto.freezed.dart';
part 'calendar_post_dto.g.dart';

@freezed
sealed class CalendarPostDto with _$CalendarPostDto {
  const factory CalendarPostDto({
    @JsonKey(name: 'calendar_id') required String calendarId,
    @JsonKey(name: 'calendar_date') required String calendarDate,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'author_username') required String authorUsername,
    @JsonKey(name: 'thumbnail_width') required int thumbnailWidth,
    @JsonKey(name: 'thumbnail_height') required int thumbnailHeight,
    @JsonKey(name: 'content_date') required String contentDate,
    @JsonKey(name: 'content_type') required String contentType,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'is_author_connected') required bool isAuthorConnected,
    @JsonKey(name: 'is_own_post') required bool isOwnPost,
    @JsonKey(name: 'is_today') required bool isToday,
    @JsonKey(name: 'published_at') required String publishedAt,
    @JsonKey(name: 'published_timezone') required String publishedTimezone,
    @JsonKey(name: 'author_avatar_url') String? authorAvatarUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    String? description,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'parent_author_id') String? parentAuthorId,
    @JsonKey(name: 'parent_thumbnail_url') String? parentThumbnailUrl,
    @JsonKey(name: 'parent_author_username') String? parentAuthorUsername,
    @JsonKey(name: 'parent_content_type') String? parentContentType,
    @JsonKey(name: 'parent_deleted_at') String? parentDeletedAt,
    @JsonKey(name: 'tagged_usernames') String? taggedUsernames,
    @JsonKey(name: 'tagged_user_ids') String? taggedUserIds,
    @JsonKey(name: 'excluded_user_ids') String? excludedUserIds,
    @JsonKey(name: 'parent_excluded_user_ids') String? parentExcludedUserIds,
  }) = _CalendarPostDto;

  factory CalendarPostDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarPostDtoFromJson(json);
}
