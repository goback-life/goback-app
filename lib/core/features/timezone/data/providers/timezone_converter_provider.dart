import 'package:cloudless/core/features/timezone/data/services/timezone_converter.dart';
import 'package:cloudless/core/features/timezone/domain/contracts/timezone_converter_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timezone_converter_provider.g.dart';

/// Provider for the timezone converter service.
///
/// This provider supplies a singleton instance of [TimezoneConverterContract]
/// for converting UTC timestamps to local timezones using IANA timezone identifiers.
@Riverpod(keepAlive: true)
TimezoneConverterContract timezoneConverter(Ref ref) {
  return TimezoneConverter();
}
