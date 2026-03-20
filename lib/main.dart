import 'package:cloudless/core/features/auth/data/handlers/authentication_background_handler.dart';
import 'package:cloudless/core/features/crashlytics/utilities/crashlytics_startup_service.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/notification/data/handlers/firebase_background_handler.dart';
import 'package:cloudless/core/features/notification/domain/providers/push_notification_provider.dart';
import 'package:cloudless/core/features/notification/domain/providers/scheduled_notification_provider.dart';
import 'package:cloudless/core/features/startup/data/config/startup_config.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_startup_service.dart';
import 'package:cloudless/core/features/timezone/utilities/timezone_startup_service.dart';
import 'package:cloudless/flavors.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );

  Startup(startupConfig).initialize().onInitializeComplete((
    ref,
    isSuccess,
  ) async {
    logger.info('App initialization completed');

    // Ensure Firebase is initialized (survives hot restart where Dart state resets)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    await CrashlyticsStartupService.initialize(ref);

    TimezoneStartupService.initialize();
    await SupabaseStartupService.initialize(ref);

    WidgetsBinding.instance.addObserver(AuthenticationBackgroundHandler(ref));

    // Push notifications — production only
    if (F.appFlavor == Flavor.production) {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize FCM for already-authenticated users (app update case)
      if (Supabase.instance.client.auth.currentSession != null) {
        await ref.read(pushNotificationProvider).initialize();
      }
    }

    // Scheduled local notifications — production only, after auth
    if (F.appFlavor == Flavor.production &&
        Supabase.instance.client.auth.currentSession != null) {
      final scheduledService = ref.read(scheduledNotificationProvider);
      await scheduledService.initialize();

      // If mid-lockout, reschedule lockout notifications
      final storable = ref.read(manualLockoutStorableProvider);
      final lockoutEnd = await storable.getLockoutEnd();
      if (lockoutEnd != null && DateTime.now().isBefore(lockoutEnd)) {
        await scheduledService.scheduleLockoutNotifications(lockoutEnd);
      }
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  });
}
