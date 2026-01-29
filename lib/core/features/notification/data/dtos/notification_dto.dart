// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

/// Data Transfer Object for individual notification records.
///
/// **Timezone Handling:**
/// The [createdAt] and [readAt] fields are ISO 8601 strings that represent
/// timestamps in UTC timezone as stored in the database. These strings are
/// later parsed and converted to the device's local timezone during the mapping
/// to domain models.
@freezed
sealed class NotificationDto with _$NotificationDto {
  const factory NotificationDto({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'notification_type') required String notificationType,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'related_user_id') required String relatedUserId,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'read_at') String? readAt,
  }) = _NotificationDto;

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);
}

