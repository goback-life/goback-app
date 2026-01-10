import 'package:intl/intl.dart';

/// Utility class for date and time formatting.
///
/// **Timezone Handling for Post Timestamps:**
/// When displaying post creation times, this class handles timezone conversion
/// automatically. Posts store their `created_at` timestamp in UTC in the database,
/// and when retrieved, these timestamps are converted to the user's local timezone
/// using [DateTime.toLocal()]. This ensures that:
/// - Each user sees post times in their own timezone
/// - The chronological order of posts remains consistent across timezones
/// - Time displays reflect the user's local time, not the server time
class DateFormatter {
  DateFormatter._();

  /// Reference year for weekday calculations (2024-01-01 is a Monday)
  static const int _referenceYear = 2024;

  /// Helper to capitalize the month in a formatted string
  static String _capitalizeMonth(String formatted) {
    final parts = formatted.split(' ');
    if (parts.length >= 2) {
      final monthPart = parts[1];
      parts[1] = monthPart[0].toUpperCase() + monthPart.substring(1);
      return parts.join(' ');
    }
    return formatted;
  }

  /// Formats a date in "day month" format in Italian
  /// @deprecated Use formatDayMonth for localization support
  static String formatCurrentDate(DateTime date) {
    return formatDayMonth(date, 'it');
  }

  /// Formats a date in "day month" format with localization and capitalized month
  /// Format: "d MMMM" (e.g. "1 October" in English, "1 Ottobre" in Italian)
  /// Converts the date to local timezone before formatting.
  static String formatDayMonth(DateTime date, String locale) {
    final localDate = date.toLocal();
    final formatter = DateFormat('d MMMM', locale);
    final formatted = formatter.format(localDate);
    return _capitalizeMonth(formatted);
  }

  /// Checks if a date is in the future compared to another date
  static bool isFutureDay(DateTime day, DateTime currentDate) {
    final currentMonthStart = DateTime(currentDate.year, currentDate.month);
    final dayMonthStart = DateTime(day.year, day.month);
    return dayMonthStart.isAfter(currentMonthStart);
  }

  /// Returns the first day of the month
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns localized weekday abbreviations
  /// Format: First letter uppercase, rest lowercase (e.g. "Lu", "Ma", "Me")
  static List<String> getWeekDayAbbreviations(
    String locale, {
    int abbreviationLength = 2,
  }) {
    return List.generate(7, (index) {
      // Using reference year 2024 where January 1st is a Monday
      final date = DateTime(_referenceYear, 1, 1 + index);
      final dayAbbr = DateFormat(
        'EEE',
        locale,
      ).format(date).substring(0, abbreviationLength).toLowerCase();
      return dayAbbr[0].toUpperCase() + dayAbbr.substring(1);
    });
  }

  /// Formats a date with full date and time in local timezone with capitalized month
  /// Format: "d MMMM yyyy - H.mm" (e.g. "1 October 2024 - 14.30")
  static String formatFullDateTime(DateTime date, String locale) {
    // Converts the date to the device's local timezone
    final localDate = date.toLocal();
    final formatter = DateFormat('d MMMM yyyy - H.mm', locale);
    final formatted = formatter.format(localDate);
    return _capitalizeMonth(formatted);
  }

  /// Formats a date with capitalized month
  /// Format: "d MMMM yyyy" (e.g. "1 October 2024")
  static String formatDate(DateTime date, String locale) {
    final localDate = date.toLocal();
    final formatter = DateFormat('d MMMM yyyy', locale);
    final formatted = formatter.format(localDate);
    return _capitalizeMonth(formatted);
  }

  /// Formats only the month name with capitalization
  /// Format: "MMMM" (e.g. "October" in English, "Ottobre" in Italian)
  static String formatMonthName(DateTime date, String locale) {
    final formatter = DateFormat('MMMM', locale);
    final monthName = formatter.format(date);
    return monthName[0].toUpperCase() + monthName.substring(1);
  }

  /// Formats only the time in H.mm format in local timezone
  /// Format: "H.mm" (e.g. "14.30", "9.45")
  static String formatTimeOnly(
    DateTime date,
    String locale, {
    bool convertToLocal = true,
  }) {
    final localDate = convertToLocal ? date.toLocal() : date;
    final formatter = DateFormat('H.mm', locale);
    return formatter.format(localDate);
  }

  /// Formats time with date if the date is different from today
  /// Format: "H.mm" if same day, "d MMMM - H.mm" if different day (e.g. "1 October - 14.30")
  static String formatTimeWithDateIfNeeded(
    DateTime date,
    String locale, {
    bool convertToLocal = true,
    DateTime? referenceDate,
  }) {
    final localDate = convertToLocal ? date.toLocal() : date;
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final postDate = DateTime(localDate.year, localDate.month, localDate.day);
    
    if (postDate == today) {
      // Same day: show only time
      return formatTimeOnly(date, locale, convertToLocal: convertToLocal);
    } else {
      // Different day: show date and time
      final formatter = DateFormat('d MMMM - H.mm', locale);
      final formatted = formatter.format(localDate);
      return _capitalizeMonth(formatted);
    }
  }
}
