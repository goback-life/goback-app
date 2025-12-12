import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_router/src/data/utilities/router_middleware_pipeline.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' as widgets;
import 'package:go_router/go_router.dart';

abstract class RouterShellRouteContract<T extends RouterShellRouteContract<T>>
    extends RouterBaseRouteContract<RouterShellRouteContract> {
  /// Creates a [RouterShellRouteContract] instance.
  const RouterShellRouteContract();

  /// The URL path corresponding to the route.
  @override
  String get path;

  /// The child routes that will be wrapped by this route.
  @override
  List<RouterBaseRouteContract> get routes => [];

  /// Function that converts the route instance to a JSON map.
  @override
  Map<String, dynamic> get toMap;

  /// Function that converts a JSON map to the route instance.
  @override
  T Function(Map<String, dynamic>) get fromMap;

  /// Optional navigator key for the shell's navigator.
  material.GlobalKey<material.NavigatorState>? get navigatorKey => null;

  /// Builds the shell UI that will wrap the child routes.
  ///
  /// The [child] parameter is the current active child route's widget.
  widgets.Widget buildShell(
      widgets.BuildContext context, GoRouterState state, widgets.Widget child);

  /// Converts this shell route to a ShellRoute for use with GoRouter.
  @override
  ShellRoute toRouteBase(RouterConfig config) {
    return ShellRoute(
      navigatorKey: navigatorKey,
      builder: (context, state, child) {
        return buildShell(context, state, child);
      },
      routes: routes.map((route) => route.toRouteBase(config)).toList(),
      redirect: (widgets.BuildContext context, GoRouterState state) async {
        if (config.middlewares.isNotEmpty) {
          final String? route =
              await RouterMiddlewarePipeline(config.middlewares)
                  .handle(context, state);
          if (route != null) {
            return route;
          }
        }
        if (middlewares.isNotEmpty && context.mounted) {
          return RouterMiddlewarePipeline(middlewares).handle(context, state);
        }
        return null;
      },
    );
  }

  @override
  String toString() => 'ShellRoutable(path: $path, name: $name)';
}
