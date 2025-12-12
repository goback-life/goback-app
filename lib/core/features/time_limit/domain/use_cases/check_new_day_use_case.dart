import 'package:cloudless/core/features/time_limit/data/storables/time_limit_usage_storable.dart';

/// Checks if a new day has started by comparing dates (ignoring time)
class CheckNewDayUseCase {
  const CheckNewDayUseCase({required this.usageStorable});

  final TimeLimitUsageStorable usageStorable;

  Future<bool> execute() async {
    final lastUsageDate = await usageStorable.getLastUsageDate();
    final now = DateTime.now();

    return !_isSameDay(lastUsageDate, now);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
