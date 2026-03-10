import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler required by Firebase.
///
/// FCM automatically displays the system notification for background messages
/// that include a notification payload, so this handler is intentionally a
/// no-op.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op — FCM handles background notification display automatically.
}
