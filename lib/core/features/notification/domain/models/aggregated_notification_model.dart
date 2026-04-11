import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'aggregated_notification_model.freezed.dart';

/// Model for aggregated notifications.
///
/// Aggregates multiple notifications of the same type for the same reference.
/// **Timezone Handling:**
/// The [updatedAt] field stores timestamps in UTC timezone,
/// as received from the database and parsed during the data mapping process.
/// The conversion to the user's local timezone happens when these timestamps
/// are formatted for display in the UI.
@freezed
sealed class AggregatedNotificationModel with _$AggregatedNotificationModel {
  const AggregatedNotificationModel._();

  const factory AggregatedNotificationModel({
    required NotificationType type,

    /// Reference ID (post_id, lockout_session_id, etc.) depending on type
    String? referenceId,

    /// Latest actor ID for display
    String? latestActorId,
    required List<String> actorIds,
    required List<String> actorUsernames,
    List<String>? actorAvatarUrls,

    /// Number of actors for this notification group
    required int actorCount,
    required DateTime updatedAt,
    required bool isRead,
    String? postThumbnailUrl,
    String? postContentType,
  }) = _AggregatedNotificationModel;
}
