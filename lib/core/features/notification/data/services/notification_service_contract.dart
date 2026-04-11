import 'package:cloudless/core/features/notification/data/dtos/aggregated_notification_dto.dart';

abstract class NotificationServiceContract {
  Future<List<AggregatedNotificationDto>> getAggregatedNotifications({
    required String userId,
    int pageSize = 20,
    DateTime? cursor,
  });

  Future<void> markNotificationsAsRead({
    required String userId,
    required String notificationType,
    String? referenceId,
  });

  Future<void> markAllNotificationsAsRead({required String userId});

  Future<int> getUnreadCount({required String userId});
}
