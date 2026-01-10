import 'package:cloudless/core/features/notification/data/dtos/aggregated_notification_dto.dart';

abstract class NotificationServiceContract {
  Future<List<AggregatedNotificationDto>> getAggregatedNotifications({
    required String userId,
    int pageSize = 20,
    int pageOffset = 0,
  });

  Future<void> markNotificationsAsRead({
    required String userId,
    required String notificationType,
    String? relatedPostId,
  });

  Future<void> markAllNotificationsAsRead({required String userId});

  Future<int> getUnreadCount({required String userId});
}

