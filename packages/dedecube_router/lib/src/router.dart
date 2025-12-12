import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_router/src/data/configs/router_config.dart';
import 'package:dedecube_router/src/data/providers/router_config_provider.dart';
import 'package:dedecube_router/src/data/utilities/router_utilities.dart';
import 'package:dedecube_router/src/domain/contracts/router_contract.dart';
import 'package:dedecube_router/src/domain/providers/can_pop_provider.dart';
import 'package:dedecube_router/src/domain/providers/go_provider.dart';
import 'package:dedecube_router/src/domain/providers/pop_provider.dart';
import 'package:dedecube_router/src/domain/providers/push_provider.dart';
import 'package:dedecube_router/src/domain/providers/push_replacement_provider.dart';
import 'package:dedecube_router/src/domain/providers/replace_provider.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

/// A [Router] class that handles navigation operations within the application.
///
/// This class implements [RouterContract] and provides methods to perform navigation operations such as:
/// **Push:** Adds a new route to the navigation stack.
/// **Go:** Navigates to a specified route.
/// **Replace:** Replaces the current route with a new one.
/// **Push Replacement:** Pushes a new route and replaces the current one.
/// **Pop:** Removes the current route from the navigation stack.
///
/// This class is responsible for managing the router configuration and ensuring that
/// the routes are valid before performing any navigation operations.
class Router implements RouterContract {
  /// Creates a [Router] instance with the provided [RouterConfig].
  ///
  /// The constructor performs the following steps:
  /// 1. Validates route paths in the provided configuration by calling RouterUtilities.validatePaths.
  /// 2. Applies the configuration to the [routerConfigNotifierProvider] so that it is accessible globally.
  Router(
    this._config,
  ) {
    RouterUtilities.validateRoutes(_config);
    riverpodContainer()
        .read(routerConfigNotifierProvider.notifier)
        .routerConfig = _config;
  }

  /// Internal configuration for router.
  ///
  /// Contains settings such as initial route, routes, and other routing parameters.
  RouterConfig _config;

  /// Gets the current router configuration.
  @override
  RouterConfig get config => _config;

  /// Updates the router's configuration.
  ///
  /// When set, the new configuration is applied, the paths are validated,
  /// and the updated configuration is propagated to the [routerConfigNotifierProvider].
  @override
  set config(RouterConfig config) {
    _config = config;
    RouterUtilities.validateRoutes(_config);
    riverpodContainer()
        .read(routerConfigNotifierProvider.notifier)
        .routerConfig = _config;
  }

  /// Pushes a given [BaseRoutable] route onto the navigation stack.
  @override
  Future<void> push(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) async {
    return await riverpodContainer().read(
      pushProvider(
        route,
        context: context,
      ).future,
    );
  }

  /// Navigates to the given route within the application.
  @override
  Future<void> go(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) async {
    return await riverpodContainer().read(
      goProvider(
        route,
        context: context,
      ).future,
    );
  }

  /// Replaces the current route with the given [BaseRoutable] route.
  @override
  Future<void> replace(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) async {
    return await riverpodContainer().read(
      replaceProvider(
        route,
        context: context,
      ).future,
    );
  }

  /// Pushes a given [BaseRoutable] route onto the navigation stack by replacing
  /// the current route.
  @override
  Future<void> pushReplacement(
    BaseRoutable route, {
    widgets.BuildContext? context,
  }) async {
    return await riverpodContainer().read(
      pushReplacementProvider(
        route,
        context: context,
      ).future,
    );
  }

  /// Pops the current route off the navigation stack.
  @override
  Future<void> pop({
    widgets.BuildContext? context,
  }) async {
    return await riverpodContainer().read(
      popProvider(
        context: context,
      ).future,
    );
  }

  /// Returns a boolean indicating whether there is a route that can be popped.
  @override
  Future<bool> canPop({
    widgets.BuildContext? context,
  }) async {
    return await riverpodContainer().read(
      canPopProvider(
        context: context,
      ).future,
    );
  }
}

/// A global accessor for the Router instance.
RouterContract get router => GetIt.I<RouterContract>();
