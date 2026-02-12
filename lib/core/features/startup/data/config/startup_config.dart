import 'package:cloudless/core/features/auth/domain/middlewares/auth_navigation_flow_middleware.dart';
import 'package:cloudless/presentation/components/goback_logo.dart';
import 'package:cloudless/presentation/components/nav_overlay/nav_overlay_wrapper.dart';
import 'package:cloudless/presentation/components/lockout_listener_widget.dart';
import 'package:cloudless/presentation/routes.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
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
    middlewares: [AuthNavigationFlowMiddleware()],
    errorPage: const ColoredBox(color: MainColors.dark),
    loadingPage: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: MainColors.dark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GobackLogo(fontSize: 48),
              const SizedBox(height: 32),
              CircularProgressIndicator(color: MainColors.accent),
            ],
          ),
        ),
      ),
    ),
    appBuilder: (context, child) => NavOverlayWrapper(
      child: LockoutListenerWidget(child: child),
    ),
  );
}
