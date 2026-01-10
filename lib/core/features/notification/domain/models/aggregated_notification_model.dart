import 'package:cloudless/core/features/notification/domain/enums/notification_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'aggregated_notification_model.freezed.dart';

/// Model for aggregated notifications.
///
/// Aggregates multiple notifications of the same type for the same post/item.
/// **Timezone Handling:**
/// The [latestCreatedAt] field stores timestamps in UTC timezone,
/// as received from the database and parsed during the data mapping process.
/// The conversion to the user's local timezone happens when these timestamps
/// are formatted for display in the UI.
@freezed
sealed class AggregatedNotificationModel with _$AggregatedNotificationModel {
  const AggregatedNotificationModel._();

  const factory AggregatedNotificationModel({
    required NotificationType type,
    String? relatedPostId,
    required List<String> actorIds,
    required List<String> actorUsernames,
    List<String>? actorAvatarUrls,
    required int count,
    required DateTime latestCreatedAt,
    required bool isRead,
    String? postThumbnailUrl,
    String? postContentType,
  }) = _AggregatedNotificationModel;
}

