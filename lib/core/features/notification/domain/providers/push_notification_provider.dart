import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/notification/data/providers/device_token_service_provider.dart';
import 'package:cloudless/core/features/notification/data/services/push_notification_service.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notification_provider.g.dart';

/// Provider for the push notification service.
///
/// Usage:
/// ```dart
/// // Initialize on app start (after auth)
/// await ref.read(pushNotificationProvider).initialize();
///
/// // Unregister on logout
/// await ref.read(pushNotificationProvider).unregister();
/// ```
@Riverpod(keepAlive: true)
PushNotificationService pushNotification(Ref ref) {
  return PushNotificationService(
    deviceTokenService: ref.watch(deviceTokenServiceProvider),
    onLockoutCompleted: () async {
      await ref.read(manualLockoutNotifierProvider.notifier).clearLockout();
    },
  );
}
