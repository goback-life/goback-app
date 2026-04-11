import 'package:cloudless/core/features/notification/domain/models/aggregated_notification_model.dart';
import 'package:cloudless/core/features/notification/domain/providers/aggregated_notifications_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

typedef AggregatedNotificationsResult = ({
  AsyncValue<Result<List<AggregatedNotificationModel>>> notifications,
  Future<void> Function() refresh,
});

/// Hook for managing aggregated notifications.
/// Follows mindful design - no auto-polling, only loads when explicitly requested.
/// Notifications are lazy-loaded when the page opens (provider is watched).
AggregatedNotificationsResult useAggregatedNotifications(
  WidgetRef ref, {
  required String userId,
  int pageSize = 20,
  DateTime? cursor,
}) {
  final notifications = ref.watch(
    aggregatedNotificationsProvider(
      userId: userId,
      pageSize: pageSize,
      cursor: cursor,
    ),
  );

  Future<void> refresh() async {
    ref.invalidate(
      aggregatedNotificationsProvider(
        userId: userId,
        pageSize: pageSize,
        cursor: cursor,
      ),
    );
  }

  return (notifications: notifications, refresh: refresh);
}
