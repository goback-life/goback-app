import 'package:dedecube_startup/dedecube_startup.dart';

/// Stores manual lockout data: lockout end timestamp and start timestamp
class ManualLockoutStorable extends Storable<Map> {
  static const _tag = '[ManualLockoutStorable]';
  @override
  String get key => 'manual_lockout';

  @override
  StorageType get storageType => StorageType.simple;

  Future<Map<String, dynamic>> getLockoutData() async {
    final data = await get(
      defaultValue: <String, dynamic>{
        'lockoutEndTimestamp': null,
        'lockoutStartTimestamp': null,
        'lockoutSessionId': null,
        'batteryAtStart': null,
      },
    );
    final result = Map<String, dynamic>.from(data);
    logger.info('$_tag getLockoutData: $result');
    return result;
  }

  Future<void> setLockoutData({
    required DateTime lockoutEndTimestamp,
    required DateTime lockoutStartTimestamp,
    String? lockoutSessionId,
    int? batteryAtStart,
  }) async {
    final dataToStore = <String, dynamic>{
      'lockoutEndTimestamp': lockoutEndTimestamp.toIso8601String(),
      'lockoutStartTimestamp': lockoutStartTimestamp.toIso8601String(),
      'lockoutSessionId': lockoutSessionId,
      'batteryAtStart': batteryAtStart,
    };
    logger.info('$_tag setLockoutData: $dataToStore');
    await set(dataToStore);

    // Verify storage immediately after setting
    final verifyData = await get(defaultValue: <String, dynamic>{});
    logger.info('$_tag setLockoutData verify: $verifyData');
  }

  Future<String?> getLockoutSessionId() async {
    final data = await getLockoutData();
    final sessionId = data['lockoutSessionId'] as String?;
    logger.info('$_tag getLockoutSessionId: $sessionId');
    return sessionId;
  }

  Future<DateTime?> getLockoutEnd() async {
    final data = await getLockoutData();
    final dateString = data['lockoutEndTimestamp'] as String?;
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  Future<DateTime?> getLockoutStart() async {
    final data = await getLockoutData();
    final dateString = data['lockoutStartTimestamp'] as String?;
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  Future<int?> getBatteryAtStart() async {
    final data = await getLockoutData();
    return data['batteryAtStart'] as int?;
  }

  Future<bool> isLockedOut() async {
    final lockoutEnd = await getLockoutEnd();
    if (lockoutEnd == null) {
      return false;
    }
    return DateTime.now().isBefore(lockoutEnd);
  }

  Future<void> clearLockout() async {
    await set(<String, dynamic>{
      'lockoutEndTimestamp': null,
      'lockoutStartTimestamp': null,
      'lockoutSessionId': null,
      'batteryAtStart': null,
    });
  }
}
