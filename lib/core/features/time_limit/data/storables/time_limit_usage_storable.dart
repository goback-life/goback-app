import 'package:dedecube_startup/dedecube_startup.dart';

/// Stores time limit usage data: used minutes and last usage date
class TimeLimitUsageStorable extends Storable<Map> {
  @override
  String get key => 'time_limit_usage';

  @override
  StorageType get storageType => StorageType.simple;

  Future<Map<String, dynamic>> getUsageData() async {
    final data = await get(
      defaultValue: <String, dynamic>{
        'usedMinutes': 0,
        'lastUsageDate': DateTime.now().toIso8601String(),
      },
    );
    return Map<String, dynamic>.from(data);
  }

  Future<void> setUsageData({
    required int usedMinutes,
    required DateTime lastUsageDate,
  }) async {
    await set(<String, dynamic>{
      'usedMinutes': usedMinutes,
      'lastUsageDate': lastUsageDate.toIso8601String(),
    });
  }

  Future<int> getUsedMinutes() async {
    final data = await getUsageData();
    return data['usedMinutes'] as int? ?? 0;
  }

  Future<DateTime> getLastUsageDate() async {
    final data = await getUsageData();
    final dateString = data['lastUsageDate'] as String?;
    return dateString != null ? DateTime.parse(dateString) : DateTime.now();
  }

  Future<void> incrementUsedMinutes() async {
    final currentMinutes = await getUsedMinutes();
    await setUsageData(
      usedMinutes: currentMinutes + 1,
      lastUsageDate: DateTime.now(),
    );
  }

  Future<void> resetUsage() async {
    await setUsageData(usedMinutes: 0, lastUsageDate: DateTime.now());
  }
}
