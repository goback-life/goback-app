// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'feed_post_dto.freezed.dart';
part 'feed_post_dto.g.dart';

/// Data Transfer Object for a post in the feed, retrieved from the database.
///
/// **Timezone Handling:**
/// The [createdAt] and [updatedAt] fields are ISO 8601 strings that represent
/// timestamps in UTC timezone as stored in the database. These strings are
/// later parsed and converted to the device's local timezone during the mapping
/// to domain models.
@freezed
sealed class FeedPostDto with _$FeedPostDto {
  const factory FeedPostDto({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'author_username') required String? authorUsername,
    @JsonKey(name: 'thumbnail_url') required String? imageUrl,
    @JsonKey(name: 'thumbnail_width') required int thumbnailWidth,
    @JsonKey(name: 'thumbnail_height') required int thumbnailHeight,
    @JsonKey(name: 'content_date') required String contentDate,
    @JsonKey(name: 'published_at') required String publishedAt,
    @JsonKey(name: 'published_timezone') required String publishedTimezone,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'content_type') required String contentType,
    @JsonKey(name: 'is_author_connected') required bool isAuthorConnected,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'parent_author_id') String? parentAuthorId,
    @JsonKey(name: 'parent_thumbnail_url') String? parentThumbnailUrl,
    @JsonKey(name: 'parent_author_username') String? parentAuthorUsername,
    @JsonKey(name: 'parent_content_type') String? parentContentType,
    @JsonKey(name: 'parent_deleted_at') String? parentDeletedAt,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'tagged_usernames') String? taggedUsernames,
    @JsonKey(name: 'tagged_user_ids') String? taggedUserIds,
    @JsonKey(name: 'excluded_user_ids') String? excludedUserIds,
    @JsonKey(name: 'parent_excluded_user_ids') String? parentExcludedUserIds,
    @JsonKey(name: 'author_avatar_url') String? authorAvatarUrl,
    String? description,
  }) = _FeedPostDto;

  factory FeedPostDto.fromJson(Map<String, dynamic> json) =>
      _$FeedPostDtoFromJson(json);
}
