/// Contract for timezone conversion operations.
///
/// Defines the interface for converting UTC timestamps to local timezones
/// using IANA timezone identifiers.
abstract interface class TimezoneConverterContract {
  /// Converts a UTC DateTime to the specified IANA timezone.
  ///
  /// Throws [ArgumentError] if the provided DateTime is not in UTC.
  ///
  /// Returns: 2025-10-28 10:15:00 (CET, UTC+1)
  DateTime toLocal(DateTime utc, String ianaTimezone);

  /// Converts a UTC DateTime to the specified IANA timezone with detailed offset info.
  ///
  /// Returns a map with:
  /// - `dateTime`: The local DateTime
  /// - `offset`: The UTC offset as a Duration
  /// - `abbreviation`: The timezone abbreviation (e.g., 'CET', 'CEST')
  ///
  /// Throws [ArgumentError] if the provided DateTime is not in UTC.
  Map<String, dynamic> toLocalWithOffset(DateTime utc, String ianaTimezone);
}
