import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class NotificationRepositoryContract {
  Future<Result<List<AggregatedNotificationModel>>> getAggregatedNotifications({
    required String userId,
    int pageSize = 20,
    int pageOffset = 0,
  });

  Future<Result<void>> markNotificationsAsRead({
    required String userId,
    required String notificationType,
    String? relatedPostId,
  });

  Future<Result<void>> markAllNotificationsAsRead({required String userId});

  Future<Result<int>> getUnreadCount({required String userId});
}

