import 'package:dedecube_router/src/data/configs/router_config.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

/// A contract defining the required router properties for an application.
abstract class RouterContract {
  /// Gets the current [RouterConfig].
  ///
  /// The [RouterConfig] encapsulates settings such as the initial route, navigator key, available routes,
  /// and diagnostic flags used throughout the navigation system.
  RouterConfig get config;

  /// Sets a new [RouterConfig].
  ///
  /// When a new configuration is set, it should update all routing settings and trigger any necessary
  /// reconfiguration in the navigation system.
  set config(RouterConfig config);

  /// Navigates to the given [route] by pushing it onto the navigation stack.
  ///
  /// This method adds a new route on top of the existing navigation stack.
  ///
  /// Parameters:
  /// - [route]: The [BaseRoutable] route to be pushed.
  /// - [context]: The BuildContext used for navigation. If not provided, the navigator key's
  ///   current context is used.
  ///
  /// Returns a [Future] that completes once the navigation operation is executed.
  Future<void> push(
    BaseRoutable route, {
    widgets.BuildContext? context,
  });

  /// Navigates to the given [route] by replacing the current route.
  ///
  /// This method replaces the current route in the navigation stack with the specified route.
  ///
  /// Parameters:
  /// - [route]: The [BaseRoutable] route to navigate to.
  /// - [context]: The BuildContext used for navigation. If not provided, the navigator key's
  ///   current context is used.
  ///
  /// Returns a [Future] that completes once the navigation operation is executed.
  Future<void> go(
    BaseRoutable route, {
    widgets.BuildContext? context,
  });

  /// Replaces the current route with the given [route].
  ///
  /// This method entirely replaces the current route in the navigation stack with the specified route.
  ///
  /// Parameters:
  /// - [route]: The [BaseRoutable] route to replace the current route.
  /// - [context]: The BuildContext used for navigation. If not provided, the navigator key's
  ///   current context is used.
  ///
  /// Returns a [Future] that completes once the route replacement operation is executed.
  Future<void> replace(
    BaseRoutable route, {
    widgets.BuildContext? context,
  });

  /// Navigates to the given [route] by pushing a replacement onto the navigation stack.
  ///
  /// This method removes the current route and pushes the new route in its place, while preserving
  /// the previous routes in the navigation stack.
  ///
  /// Parameters:
  /// - [route]: The [BaseRoutable] route to replace the current one.
  /// - [context]: The BuildContext used for navigation. If not provided, the navigator key's
  ///   current context is used.
  ///
  /// Returns a [Future] that completes once the push replacement operation is executed.
  Future<void> pushReplacement(
    BaseRoutable route, {
    widgets.BuildContext? context,
  });

  /// Pops the current route off the navigation stack.
  ///
  /// This method removes the topmost route from the navigation stack, effectively navigating back.
  ///
  /// Parameters:
  /// - [context]: The BuildContext used for navigation. If not provided, the navigator key's
  ///   current context is used.
  ///
  /// Returns a [Future] that completes once the pop operation is executed.
  Future<void> pop({
    widgets.BuildContext? context,
  });

  /// Returns a boolean indicating whether there is a route that can be popped.
  ///
  /// This method checks if the navigation stack contains at least one route
  /// that can be popped.
  ///
  /// Parameters:
  /// - [context]: The BuildContext used for navigation. If not provided, the navigator key's
  ///   current context is used.
  ///
  /// Returns a [Future<bool>] that completes with `true` if a route can be popped, or `false` otherwise.
  Future<bool> canPop({
    widgets.BuildContext? context,
  });
}
