import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_router/src/data/configs/router_config.dart'
    as router_config;
import 'package:flutter/widgets.dart';

/// An implementation of [NavigatorObserver] to monitor navigation changes.
///
/// This class tracks the navigation stack by listening to navigator events
/// such as push, pop, remove, and replace. It updates
/// a static [stack] with the names of the active routes.
class RouterObserver extends NavigatorObserver {
  /// Creates a [RouterObserver] with the given router configuration.
  RouterObserver(this.config);

  /// The router configuration.
  final router_config.RouterConfig config;

  /// The current navigation stack containing the route names.
  static List<String> stack = [];

  String? _getRouteName(Route<dynamic> route) {
    final effectiveName = route.settings.name;
    return _findRoutePathRecursively(config.routes, effectiveName);
  }

  String? _findRoutePathRecursively(
      List<BaseRoutable> routes, String? routeName) {
    for (final routable in routes) {
      if (routable.name == routeName) {
        return routable.path;
      }
      if (routable.routes.isNotEmpty) {
        final nestedPath =
            _findRoutePathRecursively(routable.routes, routeName);
        if (nestedPath != null) {
          return nestedPath;
        }
      }
    }
    return null;
  }

  /// Called when a new route has been pushed.
  ///
  /// Adds the route's name to the navigation [stack] if it's not null.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = _getRouteName(route);
    if (name != null) {
      stack.add(name);
    }
  }

  /// Called when a route has been popped off the navigator.
  ///
  /// Removes the route's name from the navigation [stack] if it's not null.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final name = _getRouteName(route);
    if (name != null) {
      stack.remove(name);
    }
  }

  /// Called when a route has been removed from the navigator.
  ///
  /// Removes the route's name from the navigation [stack] if it's not null.
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    final name = _getRouteName(route);
    if (name != null) {
      stack.remove(name);
    }
  }

  /// Called when a route has been replaced with a new route.
  ///
  /// Removes the old route's name and adds the new route's name to the navigation [stack]
  ///.
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final name = _getRouteName(oldRoute);
      if (name != null) {
        stack.remove(name);
      }
    }
    if (newRoute != null) {
      final name = _getRouteName(newRoute);
      if (name != null) {
        stack.add(name);
      }
    }
  }

  /// Returns the string representation of the current navigation [stack].
  @override
  String toString() => stack.toString();
}
