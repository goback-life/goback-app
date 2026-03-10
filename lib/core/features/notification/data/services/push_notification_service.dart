import 'dart:io';

import 'package:cloudless/core/features/notification/data/services/device_token_service.dart';
import 'package:cloudless/flavors.dart';
import 'package:cloudless/presentation/pages/friends_locked_out/friends_locked_out_routable.dart';
import 'package:cloudless/presentation/pages/notifications/notifications_routable.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling push notifications via Firebase Cloud Messaging.
///
/// All FCM operations are guarded by a production-only check.
class PushNotificationService {
  PushNotificationService({
    required this.deviceTokenService,
  });

  final DeviceTokenService deviceTokenService;

  String? _currentToken;

  bool get _isProduction => F.appFlavor == Flavor.production;

  /// Initializes FCM and registers the device token.
  ///
  /// Call this after user authentication.
  Future<void> initialize() async {
    if (!_isProduction) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // iOS: show notifications when app is in foreground
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Android: initialize local notifications plugin for foreground display
      if (Platform.isAndroid) {
        await _initAndroidNotificationChannel();
      }

      // Get token and register
      _currentToken = await messaging.getToken();
      if (_currentToken != null) {
        await _registerToken(_currentToken!);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen(_registerToken);

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background/terminated message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Cold start from notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

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
      (error) => logger.error(
        'Failed to register device token',
        exception: error,
      ),
    );
  }

  /// Unregisters the device token (call on logout).
  Future<void> unregister() async {
    if (!_isProduction || _currentToken == null) return;

    final result = await deviceTokenService.unregisterToken(_currentToken!);
    result.fold(
      (_) {
        logger.info('Device token unregistered');
        _currentToken = null;
      },
      (error) => logger.error(
        'Failed to unregister device token',
        exception: error,
      ),
    );
  }

  // ── Android foreground channel ──────────────────────────────────────────

  static const _androidChannel = AndroidNotificationChannel(
    'push_notifications',
    'Push Notifications',
    description: 'Push notifications from goback',
    importance: Importance.high,
  );

  FlutterLocalNotificationsPlugin? _localNotifications;

  Future<void> _initAndroidNotificationChannel() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    await _localNotifications!.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      _navigateForType(response.payload!);
    }
  }

  // ── Message handlers ────────────────────────────────────────────────────

  /// Handles foreground messages.
  /// iOS: handled natively via setForegroundNotificationPresentationOptions.
  /// Android: show via flutter_local_notifications.
  void _handleForegroundMessage(RemoteMessage message) {
    logger.info(
      'Received foreground message: ${message.notification?.title}',
    );

    if (Platform.isAndroid && _localNotifications != null) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications!.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['type'],
      );
    }
  }

  /// Handles message taps (app was in background or terminated).
  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type != null) {
      _navigateForType(type);
    }
  }

  /// Deep-link navigation based on event type.
  void _navigateForType(String type) {
    switch (type) {
      case 'lockout_started':
      case 'lockout_joined':
      case 'friend_joins_lockout':
        router.push(const FriendsLockedOutRoutable());
      case 'connection_request':
        router.push(const NotificationsRoutable());
    }
  }
}
