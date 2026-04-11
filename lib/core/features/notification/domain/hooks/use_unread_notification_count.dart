import 'package:cloudless/core/features/notification/domain/providers/unread_notification_count_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

/// Hook for getting unread notification count.
/// Returns AsyncValue for reactive updates.
AsyncValue<Result<int>> useUnreadNotificationCount(
  WidgetRef ref, {
  required String userId,
}) {
  return ref.watch(unreadNotificationCountProvider(userId: userId));
}
