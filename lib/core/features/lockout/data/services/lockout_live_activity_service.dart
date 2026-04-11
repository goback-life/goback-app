import 'dart:io';

import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:live_activities/live_activities.dart';

/// Wraps the `live_activities` plugin to show/hide an iOS Live Activity
/// countdown on the lock screen and Dynamic Island during lockouts.
///
/// All public methods guard on [Platform.isIOS] and swallow errors so that
/// Live Activity failures never block the lockout flow.
class LockoutLiveActivityService {
  static const _activityId = 'lockout-countdown';

  final _plugin = LiveActivities();
  bool _initialized = false;

  Future<void> init() async {
    if (!Platform.isIOS || _initialized) return;
    try {
      await _plugin.init(appGroupId: 'group.com.goback.app.live-activities');
      _initialized = true;
    } catch (e) {
      logger.warning('Live Activities init failed', exception: e);
    }
  }

  Future<void> startActivity({required DateTime lockoutEndTimestamp}) async {
    if (!Platform.isIOS) return;
    try {
      await endActivity();
      if (!_initialized) await init();
      final enabled = await _plugin.areActivitiesEnabled();
      if (!enabled) return;
      await _plugin.createActivity(_activityId, {
        'endTimestamp': lockoutEndTimestamp.millisecondsSinceEpoch ~/ 1000,
      });
    } catch (e) {
      logger.warning('Failed to start Live Activity', exception: e);
    }
  }

  Future<void> endActivity() async {
    if (!Platform.isIOS) return;
    try {
      await _plugin.endActivity(_activityId);
      await _plugin.endAllActivities();
    } catch (e) {
      logger.warning('Failed to end Live Activity', exception: e);
    }
  }
}
