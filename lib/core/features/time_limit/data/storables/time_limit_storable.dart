import 'package:cloudless/core/config/time_limit_values.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

class TimeLimitStorable extends Storable<int> {
  @override
  String get key => 'daily_time_limit';

  @override
  StorageType get storageType => StorageType.simple;

  Future<int> getTimeLimit() async {
    return await get(defaultValue: TimeLimitValues.getDefaultMinutes());
  }

  Future<void> setTimeLimit(int minutes) async {
    await set(minutes);
  }
}
