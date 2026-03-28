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
    /// Reference ID (post_id, lockout_session_id, etc.) depending on type
    @JsonKey(name: 'reference_id') String? referenceId,
    /// Latest actor ID for display
    @JsonKey(name: 'latest_actor_id') String? latestActorId,
    @JsonKey(name: 'actor_ids') required List<String> actorIds,
    @JsonKey(name: 'actor_usernames') required List<String> actorUsernames,
    @JsonKey(name: 'actor_avatar_urls') List<String>? actorAvatarUrls,
    /// Number of actors for this notification group
    @JsonKey(name: 'actor_count') required int actorCount,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'is_read') required bool isRead,
    @JsonKey(name: 'post_thumbnail_url') String? postThumbnailUrl,
    @JsonKey(name: 'post_content_type') String? postContentType,
  }) = _AggregatedNotificationDto;

  factory AggregatedNotificationDto.fromJson(Map<String, dynamic> json) =>
      _$AggregatedNotificationDtoFromJson(json);
}

