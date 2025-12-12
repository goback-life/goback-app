import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart';

/// A contract defining the required router repository for an application.
abstract class RouterRepositoryContract {
  /// Navigates to the given [route] by pushing it onto the navigation stack.
  ///
  /// - [route]: The [BaseRoutable] route to be pushed.
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  ///
  /// Returns a [Future] that completes once the push operation is executed.
  Future<void> push(
    BaseRoutable route, {
    BuildContext? context,
  });

  /// Navigates to the given [route] by replacing the current route.
  ///
  /// - [route]: The [BaseRoutable] route to navigate to.
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  ///
  /// Returns a [Future] that completes once the replace operation is executed.
  Future<void> go(
    BaseRoutable route, {
    BuildContext? context,
  });

  /// Replaces the current route with the given [route].
  ///
  /// - [route]: The [BaseRoutable] route to replace the current route.
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  ///
  /// Returns a [Future] that completes once the replacement operation is executed.
  Future<void> replace(
    BaseRoutable route, {
    BuildContext? context,
  });

  /// Navigates to the given [route] by pushing a replacement onto the navigation stack.
  ///
  /// - [route]: The [BaseRoutable] route to replace the current one.
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  ///
  /// Returns a [Future] that completes once the push replacement operation is executed.
  Future<void> pushReplacement(
    BaseRoutable route, {
    BuildContext? context,
  });

  /// Pops the current route off the navigation stack.
  ///
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  ///
  /// Returns a [Future] that completes once the pop operation is executed.
  Future<void> pop({
    BuildContext? context,
  });

  /// Returns a boolean indicating whether there is a route that can be popped.
  ///
  /// This method checks if the navigation stack contains at least one route
  /// that can be removed.
  ///
  /// - [context]: The build context (optional). If not provided, the navigator key's
  ///   current context will be used.
  ///
  /// Returns a [Future<bool>] that completes with `true` if a route can be popped,
  /// or `false` otherwise.
  Future<bool> canPop({
    BuildContext? context,
  });
}
