import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/data/configs/router_config.dart';
import 'package:dedecube_router/src/data/exceptions/router_context_not_found_exception.dart';
import 'package:dedecube_router/src/data/exceptions/router_route_not_found_exception.dart';
import 'package:dedecube_router/src/data/utilities/router_route_name_extension.dart';
import 'package:dedecube_router/src/domain/contracts/router_service_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:go_router/go_router.dart';

class RouterService implements RouterServiceContract {
  RouterService(
    Ref ref, {
    required this.config,
  });

  final RouterConfig config;

  @override
  Future<void> push(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    _validateRoute(route);
    final effectiveName = route.name;
    effectiveContext.pushNamed(
      effectiveName,
      extra: route.toMap,
    );

    if (config.isLogEnabled) {
      config.logRouterAction?.call('push', route);
    }

    return Future.value();
  }

  @override
  Future<void> go(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    _validateRoute(route);
    final effectiveName = route.name;
    effectiveContext.goNamed(
      effectiveName,
      extra: route.toMap,
    );

    if (config.isLogEnabled) {
      config.logRouterAction?.call('go', route);
    }

    return Future.value();
  }

  @override
  Future<void> replace(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    _validateRoute(route);
    final effectiveName = route.name;
    effectiveContext.replaceNamed(
      effectiveName,
      extra: route.toMap,
    );

    if (config.isLogEnabled) {
      config.logRouterAction?.call('replace', route);
    }

    return Future.value();
  }

  @override
  Future<void> pushReplacement(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    final effectiveName = route.name;
    _validateRoute(route);
    effectiveContext.pushReplacementNamed(
      effectiveName,
      extra: route.toMap,
    );

    if (config.isLogEnabled) {
      config.logRouterAction?.call('pushReplacement', route);
    }

    return Future.value();
  }

  @override
  Future<void> pop({
    widgets.BuildContext? context,
  }) {
    _getEffectiveContext(context).pop();

    if (config.isLogEnabled) {
      config.logRouterAction?.call('pop', null);
    }

    return Future.value();
  }

  @override
  Future<bool> canPop({
    widgets.BuildContext? context,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    return Future<bool>.value(effectiveContext.canPop());
  }

  widgets.BuildContext _getEffectiveContext(widgets.BuildContext? context) {
    final effectiveContext = context ?? config.navigatorKey?.currentContext;
    if (effectiveContext == null) {
      throw RouterContextNotFoundException();
    }

    return effectiveContext;
  }

  void _validateRoute(BaseRoutable route) {
    final effectiveName = route.name;

    // Check if the route exists at any level of nesting
    final bool routeExists =
        _routeExistsRecursively(config.routes, effectiveName);

    if (!routeExists) {
      throw RouterRouteNotFoundException(route);
    }
  }

  /// Recursively checks if a route with the specified name exists in the routes or their children
  bool _routeExistsRecursively(List<BaseRoutable> routes, String routeName) {
    // Check current level
    if (routes.any((routable) => routable.name == routeName)) {
      return true;
    }

    // Check nested routes
    for (final routable in routes) {
      if (routable.routes.isNotEmpty) {
        if (_routeExistsRecursively(routable.routes, routeName)) {
          return true;
        }
      }
    }

    return false;
  }
}
