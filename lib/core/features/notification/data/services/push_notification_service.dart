import 'dart:io';

import 'package:cloudless/core/features/notification/data/services/device_token_service.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

/// Service for handling push notifications via Firebase Cloud Messaging.
///
/// Note: This service requires firebase_messaging package to be added to pubspec.yaml:
/// ```yaml
/// dependencies:
///   firebase_messaging: ^15.1.0
/// ```
class PushNotificationService {
  PushNotificationService({
    required this.deviceTokenService,
  });

  final DeviceTokenService deviceTokenService;

  String? _currentToken;

  /// Initializes FCM and registers the device token.
  ///
  /// Call this after user authentication.
  Future<void> initialize() async {
    try {
      // TODO: Uncomment when firebase_messaging is added to pubspec.yaml
      // final messaging = FirebaseMessaging.instance;

      // Request permission (iOS)
      // await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );

      // Get the token
      // _currentToken = await messaging.getToken();

      // if (_currentToken != null) {
      //   await _registerToken(_currentToken!);
      // }

      // Listen for token refresh
      // messaging.onTokenRefresh.listen(_registerToken);

      // Handle foreground messages
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated message taps
      // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Check for initial message (app opened from terminated state via notification)
      // final initialMessage = await messaging.getInitialMessage();
      // if (initialMessage != null) {
      //   _handleMessageTap(initialMessage);
      // }

      logger.info('Push notification service initialized');
    } catch (e) {
      logger.error('Failed to initialize push notifications', exception: e);
    }
  }

  /// Registers the device token with the backend.
  Future<void> _registerToken(String token) async {
    _currentToken = token;
    final platform = Platform.isIOS ? 'ios' : 'android';

    final result = await deviceTokenService.registerToken(
      token: token,
      platform: platform,
    );

    result.fold(
      (_) => logger.info('Device token registered'),
      (error) => logger.error('Failed to register device token', exception: error),
    );
  }

  /// Unregisters the device token (call on logout).
  Future<void> unregister() async {
    if (_currentToken == null) return;

    final result = await deviceTokenService.unregisterToken(_currentToken!);
    result.fold(
      (_) {
        logger.info('Device token unregistered');
        _currentToken = null;
      },
      (error) => logger.error('Failed to unregister device token', exception: error),
    );
  }

  // /// Handles foreground messages (app is open).
  // void _handleForegroundMessage(RemoteMessage message) {
  //   logger.info('Received foreground message: ${message.notification?.title}');
  //   // Could show a local notification or update UI
  // }

  // /// Handles message taps (app was in background or terminated).
  // void _handleMessageTap(RemoteMessage message) {
  //   final data = message.data;
  //   final type = data['type'];

  //   if (type == 'lockout_started') {
  //     // Navigate to friends locked out page
  //     router.push(const FriendsLockedOutRoutable());
  //   }
  // }
}
