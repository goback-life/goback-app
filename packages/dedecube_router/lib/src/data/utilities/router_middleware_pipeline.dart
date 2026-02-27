import 'package:dedecube_router/src/domain/contracts/router_middleware_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:go_router/go_router.dart';

/// A pipeline that processes navigation middleware sequentially.
class RouterMiddlewarePipeline {
  RouterMiddlewarePipeline(List<Middleware> middlewares)
      : _middlewares = middlewares;

  final List<Middleware> _middlewares;

  /// Handles the middleware pipeline for a given [context] and [state].
  ///
  /// Iterates through the list of middlewares and evaluates each one by calling its [RouterMiddlewareContract.handle]
  /// method. If any middleware returns a modified [BaseRoutable] instance (indicating redirection), its path is
  /// returned immediately. If no middleware alters the navigation flow, the method returns `null` to indicate
  /// that normal navigation should proceed.
  ///
  /// Returns a [Future] that completes with the path to redirect to if any middleware triggers a redirection,
  /// or `null` if navigation continues without interruption.
  Future<String?> handle(
    widgets.BuildContext context,
    GoRouterState state,
  ) async {
    for (final middleware in _middlewares) {
      if (middleware.excludedRoutes.any((route) => route.path == state.path)) {
        continue;
      }
      final operation = await middleware.handle(context, state);
      if (operation != null) {
        return operation.path;
      }
    }
    return null;
  }
}
