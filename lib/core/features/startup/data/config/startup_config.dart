import 'package:cloudless/core/features/auth/domain/middlewares/auth_navigation_flow_middleware.dart';
import 'package:cloudless/core/features/time_limit/domain/middlewares/time_limit_middleware.dart';
import 'package:cloudless/presentation/components/time_limit_listener_widget.dart';
import 'package:cloudless/presentation/routes.dart';
import 'package:cloudless/presentation/themes/main_theme.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

StartupConfig get startupConfig {
  return StartupConfig(
    supportedThemes: [MainTheme()],
    initialTheme: MainTheme(),
    routes: routes,
    localizationsDelegates: [...PhoneFieldLocalization.delegates],
    middlewares: [AuthNavigationFlowMiddleware(), TimeLimitMiddleware()],
    errorPage: Container(color: Colors.white),
    loadingPage: Container(color: Colors.white),
    appBuilder: (context, child) => TimeLimitListenerWidget(child: child),
  );
}
