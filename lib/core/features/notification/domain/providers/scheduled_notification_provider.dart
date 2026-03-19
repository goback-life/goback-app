import 'package:cloudless/core/features/notification/data/services/scheduled_notification_service.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scheduled_notification_provider.g.dart';

@Riverpod(keepAlive: true)
ScheduledNotificationService scheduledNotification(Ref ref) {
  return ScheduledNotificationService();
}
