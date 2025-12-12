import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:timezone/data/latest.dart' as tz;

/// Utility service for initializing timezone database during app startup.
///
/// This service should be called once during app initialization to load
/// the timezone database required for timezone conversions.
class TimezoneStartupService {
  /// Initializes the timezone database for local time conversions.
  ///
  /// This method loads timezone data required for converting between UTC
  /// and local timezones using IANA timezone identifiers (e.g., "Europe/Rome").
  ///
  /// Should be called during app startup, before any timezone conversions.
  static void initialize() {
    tz.initializeTimeZones();
    logger.log('Timezone database initialized successfully');
  }
}
