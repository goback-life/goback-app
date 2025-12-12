import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A contract defining the required middleware properties for an application.
abstract class RouterMiddlewareContract {
  /// A list of [BaseRoutable] instances that this middleware should ignore.
  ///
  /// When a navigation event occurs, the router examines this list to determine
  /// whether it should bypass the middleware logic for the destination route.
  /// For example, if a user navigates to a route whose identifier matches one of the
  /// routes in [excludedRoutes], the middleware’s handle method will be skipped,
  /// and the navigation will proceed as normal.
  List<BaseRoutable> get excludedRoutes => [];

  /// Intercepts a navigation event and performs middleware operations.
  ///
  /// Returns a [Future] that completes with a [BaseRoutable] instance if the middleware opts to alter
  /// the navigation (e.g., by redirecting to a different route), or `null` to continue normal navigation.
  Future<BaseRoutable?> handle(
    BuildContext context,
    GoRouterState state,
  );
}
