/// Contract for converting UTC timestamps to local timezones using IANA identifiers.
abstract interface class TimezoneConverterContract {
  /// Converts a UTC DateTime to the specified IANA timezone.
  /// Throws [ArgumentError] if the provided DateTime is not in UTC.
  DateTime toLocal(DateTime utc, String ianaTimezone);

  /// Converts a UTC DateTime with detailed offset info.
  /// Returns map with keys: 'dateTime', 'offset', 'abbreviation'.
  /// Throws [ArgumentError] if the provided DateTime is not in UTC.
  Map<String, dynamic> toLocalWithOffset(DateTime utc, String ianaTimezone);
}
