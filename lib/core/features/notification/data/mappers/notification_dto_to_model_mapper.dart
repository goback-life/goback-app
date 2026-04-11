import 'package:cloudless/core/features/notification/data/dtos/notification_dto.dart';
import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:cloudless/core/features/notification/domain/models/notification_model.dart';

/// Mapper that converts [NotificationDto] to [NotificationModel].
///
/// **Timezone Handling:**
/// The `createdAt` and `readAt` timestamps from the DTO are in ISO 8601 format
/// with UTC timezone. When parsed with [DateTime.tryParse], the resulting DateTime
/// objects represent the UTC time. The conversion to the user's local timezone
/// happens later when these timestamps are formatted for display in the UI.
class NotificationDtoToModelMapper {
  NotificationModel mapDto(NotificationDto dto) {
    final notificationType = NotificationType.fromValue(dto.notificationType);

    return NotificationModel(
      id: dto.id,
      userId: dto.userId,
      type: notificationType,
      referenceId: dto.referenceId,
      relatedUserId: dto.relatedUserId,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
      readAt: dto.readAt != null ? DateTime.tryParse(dto.readAt!) : null,
    );
  }

  List<NotificationModel> mapDtoList(List<NotificationDto> dtos) {
    return dtos.map(mapDto).toList();
  }
}
