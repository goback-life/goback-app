import 'package:dedecube_startup/dedecube_startup.dart';

/// Stores manual lockout data: lockout end timestamp and start timestamp
class ManualLockoutStorable extends Storable<Map> {
  @override
  String get key => 'manual_lockout';

  @override
  StorageType get storageType => StorageType.simple;

  Future<Map<String, dynamic>> getLockoutData() async {
    final data = await get(defaultValue: <String, dynamic>{
      'lockoutEndTimestamp': null,
      'lockoutStartTimestamp': null,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<void> setLockoutData({
    required DateTime lockoutEndTimestamp,
    required DateTime lockoutStartTimestamp,
  }) async {
    await set(<String, dynamic>{
      'lockoutEndTimestamp': lockoutEndTimestamp.toIso8601String(),
      'lockoutStartTimestamp': lockoutStartTimestamp.toIso8601String(),
    });
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
    });
  }
}

