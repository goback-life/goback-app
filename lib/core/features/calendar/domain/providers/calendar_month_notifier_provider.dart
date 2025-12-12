import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_month_notifier_provider.g.dart';

/// Provider that manages the currently selected month in the calendar view.
/// This is used to synchronize the calendar display when navigating between posts.
@Riverpod(keepAlive: false)
class CalendarMonthNotifier extends _$CalendarMonthNotifier {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Updates the selected month to the given date.
  void setMonth(DateTime date) {
    state = DateTime(date.year, date.month);
  }

  /// Resets the selected month to the current month.
  void reset() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}
