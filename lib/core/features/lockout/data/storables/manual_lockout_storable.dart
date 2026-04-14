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
        'isOpenEnded': false,
        'venueName': null,
        'venueTagId': null,
        'wasChargingDuringLockout': false,
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
    bool isOpenEnded = false,
    String? venueName,
    String? venueTagId,
    bool wasChargingDuringLockout = false,
  }) async {
    final dataToStore = <String, dynamic>{
      'lockoutEndTimestamp': lockoutEndTimestamp.toIso8601String(),
      'lockoutStartTimestamp': lockoutStartTimestamp.toIso8601String(),
      'lockoutSessionId': lockoutSessionId,
      'batteryAtStart': batteryAtStart,
      'isOpenEnded': isOpenEnded,
      'venueName': venueName,
      'venueTagId': venueTagId,
      'wasChargingDuringLockout': wasChargingDuringLockout,
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

  Future<bool> getIsOpenEnded() async {
    final data = await getLockoutData();
    return (data['isOpenEnded'] as bool?) ?? false;
  }

  Future<String?> getVenueName() async {
    final data = await getLockoutData();
    return data['venueName'] as String?;
  }

  Future<String?> getVenueTagId() async {
    final data = await getLockoutData();
    return data['venueTagId'] as String?;
  }

  Future<bool> isLockedOut() async {
    final lockoutEnd = await getLockoutEnd();
    if (lockoutEnd == null) {
      return false;
    }
    return DateTime.now().isBefore(lockoutEnd);
  }

  Future<void> clearLockoutEnd() async {
    final data = await getLockoutData();
    data['lockoutEndTimestamp'] = null;
    await set(data);
  }

  Future<bool> getWasChargingDuringLockout() async {
    final data = await getLockoutData();
    return (data['wasChargingDuringLockout'] as bool?) ?? false;
  }

  Future<void> setWasChargingDuringLockout({required bool value}) async {
    final data = await getLockoutData();
    data['wasChargingDuringLockout'] = value;
    await set(data);
  }

  Future<void> clearLockout() async {
    await set(<String, dynamic>{
      'lockoutEndTimestamp': null,
      'lockoutStartTimestamp': null,
      'lockoutSessionId': null,
      'batteryAtStart': null,
      'isOpenEnded': false,
      'venueName': null,
      'venueTagId': null,
      'wasChargingDuringLockout': false,
    });
  }
}
