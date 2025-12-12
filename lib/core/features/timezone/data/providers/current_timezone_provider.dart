import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_timezone_provider.g.dart';

/// Provider that returns the device's current IANA timezone identifier.
@riverpod
Future<String> currentTimezone(Ref ref) async {
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  return timezoneInfo.identifier;
}
