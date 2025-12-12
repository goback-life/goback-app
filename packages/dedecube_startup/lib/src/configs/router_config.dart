import 'package:dedecube_environment/dedecube_environment.dart';
import 'package:dedecube_router/dedecube_router.dart';
import 'package:dedecube_startup/src/utilities/startup_navigator_key.dart';

/// Configuration for the router service.
///
/// This function provides a [RouterConfig] instance with settings loaded from environment variables:
/// * initialLocation: The initial route location when the app starts ('ROUTER_INITIAL_LOCATION')
/// * routes: List of routes to be used by the router
/// * navigatorKey: Global navigator key for the app
RouterConfig routerConfig(
  List<BaseRoutable> routes,
  List<Middleware> middlewares,
  Function(String action, BaseRoutable?)? logRouterAction,
) {
  final routerConfig = RouterConfig(
    initialLocation: environment.tryGetString('ROUTER_INITIAL_LOCATION'),
    routes: routes,
    middlewares: middlewares,
    navigatorKey: startupNavigatorKey,
    isLogEnabled: environment.tryGetBool('APP_DEBUG_ROUTER_DIAGNOSTICS'),
    logRouterAction: logRouterAction,
  );

  return routerConfig;
}
