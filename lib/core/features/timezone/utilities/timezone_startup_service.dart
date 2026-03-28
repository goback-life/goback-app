import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:timezone/data/latest.dart' as tz;

/// Initializes the timezone database during app startup.
class TimezoneStartupService {
  static void initialize() {
    tz.initializeTimeZones();
    logger.log('Timezone database initialized successfully');
  }
}
