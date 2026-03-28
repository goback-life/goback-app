import 'package:cloudless/core/features/timezone/domain/contracts/timezone_converter_contract.dart';
import 'package:timezone/timezone.dart' as tz;

class TimezoneConverter implements TimezoneConverterContract {
  @override
  DateTime toLocal(DateTime utc, String ianaTimezone) {
    if (!utc.isUtc) throw ArgumentError('DateTime must be in UTC');
    return tz.TZDateTime.from(utc, tz.getLocation(ianaTimezone));
  }

  @override
  Map<String, dynamic> toLocalWithOffset(DateTime utc, String ianaTimezone) {
    if (!utc.isUtc) throw ArgumentError('DateTime must be in UTC');
    final tzDateTime = tz.TZDateTime.from(utc, tz.getLocation(ianaTimezone));
    return {
      'dateTime': tzDateTime,
      'offset': Duration(milliseconds: tzDateTime.timeZoneOffset.inMilliseconds),
      'abbreviation': tzDateTime.timeZoneName,
    };
  }
}
