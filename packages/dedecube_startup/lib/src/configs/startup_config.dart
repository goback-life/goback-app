import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_startup/src/contracts/startup_config_contract.dart';
import 'package:dedecube_themify/dedecube_themify.dart';
import 'package:flutter/material.dart';

class StartupConfig implements StartupConfigContract {
  StartupConfig({
    List<BaseRoutable>? routes,
    List<Middleware>? middlewares,
    this.supportedThemes,
    this.initialTheme,
    this.loadingPage,
    this.errorPage,
    this.appBuilder,
    this.localizationsDelegates,
  })  : routes = routes ?? <BaseRoutable>[],
        middlewares = middlewares ?? <Middleware>[];

  @override
  final List<BaseRoutable> routes;

  @override
  final List<Middleware> middlewares;

  @override
  final List<Themable>? supportedThemes;

  @override
  final Themable? initialTheme;

  @override
  Widget? errorPage;

  @override
  Widget? loadingPage;

  @override
  final Widget Function(BuildContext context, Widget child)? appBuilder;

  @override
  final List<LocalizationsDelegate>? localizationsDelegates;
}
