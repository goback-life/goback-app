import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'notification_model.freezed.dart';

/// Model for individual notification records.
///
/// **Timezone Handling:**
/// The [createdAt] and [readAt] fields store timestamps in UTC timezone,
/// as received from the database and parsed during the data mapping process.
/// The conversion to the user's local timezone happens when these timestamps
/// are formatted for display in the UI.
@freezed
sealed class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    required String id,
    required String userId,
    required NotificationType type,
    String? referenceId,
    required String relatedUserId,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _NotificationModel;
}
