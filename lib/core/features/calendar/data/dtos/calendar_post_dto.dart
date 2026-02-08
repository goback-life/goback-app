// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'calendar_post_dto.freezed.dart';
part 'calendar_post_dto.g.dart';

@freezed
sealed class CalendarPostDto with _$CalendarPostDto {
  const factory CalendarPostDto({
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'author_username') required String authorUsername,
    @JsonKey(name: 'thumbnail_width') required int thumbnailWidth,
    @JsonKey(name: 'thumbnail_height') required int thumbnailHeight,
    @JsonKey(name: 'content_type') required String contentType,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'is_author_connected') required bool isAuthorConnected,
    @JsonKey(name: 'is_own_post') required bool isOwnPost,
    @JsonKey(name: 'published_at') required String publishedAt,
    @JsonKey(name: 'published_timezone') required String publishedTimezone,
    @JsonKey(name: 'author_avatar_url') String? authorAvatarUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    String? description,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'tagged_usernames') String? taggedUsernames,
    @JsonKey(name: 'tagged_user_ids') String? taggedUserIds,
    /// Excluded user IDs as UUID[] array
    @JsonKey(name: 'excluded_user_ids') List<String>? excludedUserIds,
    /// The lockout session ID this post was created from
    @JsonKey(name: 'lockout_id') String? lockoutId,
    /// When the post was saved to calendar (legacy, now optional)
    @JsonKey(name: 'calendar_saved_at') String? calendarSavedAt,
  }) = _CalendarPostDto;

  factory CalendarPostDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarPostDtoFromJson(json);
}
