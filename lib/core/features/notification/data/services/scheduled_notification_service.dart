import 'package:cloudless/flavors.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

/// Client-side scheduled local notifications (no server involved).
///
/// Manages four notification types:
/// - Daily 9 AM / 3 PM reminders (recurring, skipped while locked out)
/// - Mid-lockout encouragement (one-shot)
/// - Post-lockout nudge 1 h after unlock (one-shot)
class ScheduledNotificationService {
  static const _kDailyMorningId = 1001;
  static const _kDailyAfternoonId = 1002;
  static const _kMidLockoutId = 2001;
  static const _kPostLockoutId = 2002;

  static const _channelId = 'scheduled_reminders';
  static const _channelName = 'Scheduled Reminders';

  bool get _isProduction => F.appFlavor == Flavor.production;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Creates the notification channel and schedules daily reminders.
  Future<void> initialize() async {
    if (!_isProduction) return;
    if (_initialized) return;

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Android channel
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Daily reminders and lockout nudges',
            importance: Importance.high,
          ),
        );

    _initialized = true;
    await scheduleDailyReminders();
    logger.info('Scheduled notification service initialized');
  }

  /// Schedules recurring 9 AM and 3 PM daily notifications.
  Future<void> scheduleDailyReminders() async {
    if (!_isProduction) return;

    final location = await _localLocation();

    await _plugin.zonedSchedule(
      _kDailyMorningId,
      'goback',
      'start the day with a lockout! press goback',
      _nextTimeOfDay(9, 0, location),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _plugin.zonedSchedule(
      _kDailyAfternoonId,
      'goback',
      'still hours left to the day, press goback and live!',
      _nextTimeOfDay(15, 0, location),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    logger.info('Daily reminders scheduled (9 AM, 3 PM)');
  }

  /// Cancels the two daily recurring notifications.
  Future<void> cancelDailyReminders() async {
    await _plugin.cancel(_kDailyMorningId);
    await _plugin.cancel(_kDailyAfternoonId);
  }

  /// Call when a lockout starts. Cancels daily reminders and schedules
  /// mid-lockout + post-lockout one-shot notifications.
  ///
  /// For venue lockouts pass [venueName] to include the venue in notification
  /// bodies (e.g. "how does it feel at The Dunvegan?"). For open-ended
  /// venue lockouts the midpoint is 1 hour after start and the post-lockout
  /// notification is skipped (we don't know when they'll finish).
  Future<void> scheduleLockoutNotifications(
    DateTime endsAt, {
    String? venueName,
  }) async {
    if (!_isProduction) return;

    await cancelDailyReminders();

    final location = await _localLocation();
    final now = tz.TZDateTime.now(location);
    final end = tz.TZDateTime.from(endsAt, location);
    final isVenue = venueName != null && venueName.isNotEmpty;

    // For venue lockouts: send encouragement after 1 hour.
    // For timed lockouts: send at midpoint.
    final midpoint = isVenue
        ? now.add(const Duration(hours: 1))
        : now.add(end.difference(now) ~/ 2);

    if (midpoint.isAfter(now)) {
      final midBody = isVenue
          ? "how does it feel at $venueName? stay off the phone a little longer"
          : "how does it feel? Don't answer that. Just stay where you are";
      await _plugin.zonedSchedule(
        _kMidLockoutId,
        'goback',
        midBody,
        midpoint,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Skip post-lockout nudge for open-ended venue lockouts (unknown end time)
    if (!isVenue) {
      final postLockout = end.add(const Duration(hours: 1));
      await _plugin.zonedSchedule(
        _kPostLockoutId,
        'goback',
        "You've been back online, the button is still there! Life awaits",
        postLockout,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    logger.info(
      isVenue
          ? 'Venue lockout notifications scheduled for $venueName'
          : 'Lockout notifications scheduled (mid + post)',
    );
  }

  /// Call when a lockout ends or is cleared. Cancels lockout notifications
  /// and reschedules the daily reminders.
  Future<void> cancelLockoutNotifications() async {
    if (!_isProduction) return;

    await _plugin.cancel(_kMidLockoutId);
    await _plugin.cancel(_kPostLockoutId);
    await scheduleDailyReminders();
    logger.info('Lockout notifications cancelled, daily reminders restored');
  }

  /// Cancels all four scheduled notifications (e.g. on logout).
  Future<void> cancelAll() async {
    await _plugin.cancel(_kDailyMorningId);
    await _plugin.cancel(_kDailyAfternoonId);
    await _plugin.cancel(_kMidLockoutId);
    await _plugin.cancel(_kPostLockoutId);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static NotificationDetails get _notificationDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Daily reminders and lockout nudges',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Returns the device's local [tz.Location].
  Future<tz.Location> _localLocation() async {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    return tz.getLocation(timezoneInfo.identifier);
  }

  /// Returns the next occurrence of [hour]:[minute] in the given [location].
  tz.TZDateTime _nextTimeOfDay(int hour, int minute, tz.Location location) {
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
