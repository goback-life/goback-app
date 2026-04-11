import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class NotificationRepositoryContract {
  Future<Result<List<AggregatedNotificationModel>>> getAggregatedNotifications({
    required String userId,
    int pageSize = 20,
    DateTime? cursor,
  });

  Future<Result<void>> markNotificationsAsRead({
    required String userId,
    required String notificationType,
    String? referenceId,
  });

  Future<Result<void>> markAllNotificationsAsRead({required String userId});

  Future<Result<int>> getUnreadCount({required String userId});
}
