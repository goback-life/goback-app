import 'package:cloudless/core/features/auth/data/handlers/authentication_background_handler.dart';
import 'package:cloudless/core/features/crashlytics/utilities/crashlytics_startup_service.dart';
import 'package:cloudless/core/features/startup/data/config/startup_config.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_startup_service.dart';
import 'package:cloudless/core/features/time_limit/data/handlers/time_limit_lifecycle_handler.dart';
import 'package:cloudless/core/features/timezone/utilities/timezone_startup_service.dart';
import 'package:cloudless/flavors.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );

  Startup(startupConfig).initialize().onInitializeComplete((
    ref,
    isSuccess,
  ) async {
    logger.info('App initialization completed');
    await CrashlyticsStartupService.initialize(ref);

    TimezoneStartupService.initialize();
    await SupabaseStartupService.initialize(ref);

    WidgetsBinding.instance.addObserver(AuthenticationBackgroundHandler(ref));

    WidgetsBinding.instance.addObserver(TimeLimitLifecycleHandler(ref));

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  });
}
