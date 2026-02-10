import 'package:dedecube_startup/dedecube_startup.dart';

/// Stores the last date the user was prompted for memorable post selection.
/// This prevents showing the popup multiple times for the same day.
class LastSelectionDateStorable extends Storable<String> {
  @override
  String get key => 'last_selection_prompt_date';

  @override
  StorageType get storageType => StorageType.simple;

  /// Gets the last date the user was prompted.
  /// Returns null if never prompted.
  Future<DateTime?> getLastPromptDate() async {
    final dateStr = await get(defaultValue: '');
    if (dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Sets the last prompt date to today.
  Future<void> setPromptedToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await set(today);
  }

  /// Checks if the user has already been prompted today.
  Future<bool> wasPromptedToday() async {
    final lastDate = await getLastPromptDate();
    if (lastDate == null) return false;

    final today = DateTime.now();
    return lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;
  }
}
