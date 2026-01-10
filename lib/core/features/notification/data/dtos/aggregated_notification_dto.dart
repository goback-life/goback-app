// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'aggregated_notification_dto.freezed.dart';
part 'aggregated_notification_dto.g.dart';

/// Data Transfer Object for aggregated notifications from the RPC function.
///
/// Aggregates multiple notifications of the same type for the same post/item.
/// **Timezone Handling:**
/// The [latestCreatedAt] field is an ISO 8601 string that represents
/// timestamp in UTC timezone as stored in the database. This string is
/// later parsed and converted to the device's local timezone during the mapping
/// to domain models.
@freezed
sealed class AggregatedNotificationDto with _$AggregatedNotificationDto {
  const factory AggregatedNotificationDto({
    @JsonKey(name: 'notification_type') required String notificationType,
    @JsonKey(name: 'related_post_id') String? relatedPostId,
    @JsonKey(name: 'actor_ids') required List<String> actorIds,
    @JsonKey(name: 'actor_usernames') required List<String> actorUsernames,
    @JsonKey(name: 'actor_avatar_urls') List<String>? actorAvatarUrls,
    required int count,
    @JsonKey(name: 'latest_created_at') required String latestCreatedAt,
    @JsonKey(name: 'is_read') required bool isRead,
    @JsonKey(name: 'post_thumbnail_url') String? postThumbnailUrl,
    @JsonKey(name: 'post_content_type') String? postContentType,
  }) = _AggregatedNotificationDto;

  /// Creates DTO from RPC response JSON, handling JSONB array conversions
  factory AggregatedNotificationDto.fromRpcJson(Map<String, dynamic> json) {
    // Convert JSONB arrays (List<dynamic>) to List<String>
    List<String> parseJsonbArray(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    final actorIds = parseJsonbArray(json['actor_ids']);
    final actorUsernames = parseJsonbArray(json['actor_usernames']);
    final actorAvatarUrls = json['actor_avatar_urls'] != null 
        ? parseJsonbArray(json['actor_avatar_urls'])
        : null;

    return AggregatedNotificationDto(
      notificationType: json['notification_type'] as String,
      relatedPostId: json['related_post_id'] as String?,
      actorIds: actorIds,
      actorUsernames: actorUsernames,
      actorAvatarUrls: actorAvatarUrls,
      count: json['count'] as int,
      latestCreatedAt: json['latest_created_at'] as String,
      isRead: json['is_read'] as bool,
      postThumbnailUrl: json['post_thumbnail_url'] as String?,
      postContentType: json['post_content_type'] as String?,
    );
  }

  factory AggregatedNotificationDto.fromJson(Map<String, dynamic> json) =>
      _$AggregatedNotificationDtoFromJson(json);
}

