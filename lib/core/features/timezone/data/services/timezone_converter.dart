import 'package:cloudless/core/features/timezone/domain/contracts/timezone_converter_contract.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for converting UTC timestamps to local timezone.
///
/// This service handles timezone conversions using IANA timezone identifiers,
/// properly accounting for daylight saving time and historical timezone changes.
class TimezoneConverter implements TimezoneConverterContract {
  @override
  DateTime toLocal(DateTime utc, String ianaTimezone) {
    if (!utc.isUtc) {
      throw ArgumentError('DateTime must be in UTC');
    }

    final location = tz.getLocation(ianaTimezone);
    return tz.TZDateTime.from(utc, location);
  }

  @override
  Map<String, dynamic> toLocalWithOffset(DateTime utc, String ianaTimezone) {
    if (!utc.isUtc) {
      throw ArgumentError('DateTime must be in UTC');
    }

    final location = tz.getLocation(ianaTimezone);
    final tzDateTime = tz.TZDateTime.from(utc, location);

    return {
      'dateTime': tzDateTime,
      'offset': Duration(
        milliseconds: tzDateTime.timeZoneOffset.inMilliseconds,
      ),
      'abbreviation': tzDateTime.timeZoneName,
    };
  }
}
