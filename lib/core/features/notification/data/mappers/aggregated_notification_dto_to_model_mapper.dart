import 'package:cloudless/core/features/notification/data/dtos/aggregated_notification_dto.dart';
import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';

/// Mapper that converts [AggregatedNotificationDto] to [AggregatedNotificationModel].
///
/// **Timezone Handling:**
/// The `updatedAt` timestamp from the DTO is in ISO 8601 format
/// with UTC timezone. When parsed with [DateTime.tryParse], the resulting DateTime
/// object represents the UTC time. The conversion to the user's local timezone
/// happens later when these timestamps are formatted for display in the UI.
class AggregatedNotificationDtoToModelMapper {
  AggregatedNotificationModel mapDto(AggregatedNotificationDto dto) {
    final notificationType = NotificationType.fromValue(dto.notificationType);

    return AggregatedNotificationModel(
      type: notificationType,
      referenceId: dto.referenceId,
      latestActorId: dto.latestActorId,
      actorIds: dto.actorIds,
      actorUsernames: dto.actorUsernames,
      actorAvatarUrls: dto.actorAvatarUrls,
      actorCount: dto.actorCount,
      updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
      isRead: dto.isRead,
      postThumbnailUrl: dto.postThumbnailUrl,
      postContentType: dto.postContentType,
    );
  }

  List<AggregatedNotificationModel> mapDtoList(
    List<AggregatedNotificationDto> dtos,
  ) {
    return dtos.map(mapDto).toList();
  }
}
