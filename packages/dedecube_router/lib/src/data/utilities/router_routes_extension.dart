import 'package:dedecube_router/dedecube_router.dart';
import 'package:go_router/go_router.dart';

/// Extension on [RouterConfig] that provides utility methods to convert routes.
extension RouterRoutesExtension on RouterConfig {
  /// Converts the configured routes to [GoRouter] routes.
  ///
  /// This method maps each [BaseRoutable] in the configuration to its corresponding
  /// [RouteBase] implementation by calling the toRouteBase method.
  List<RouteBase> toGoRouterRoutes() {
    return routes.map((route) => route.toRouteBase(this)).toList();
  }
}
