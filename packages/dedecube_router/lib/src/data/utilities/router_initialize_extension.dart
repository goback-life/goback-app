import 'package:dedecube_router/src/data/observers/router_observer.dart';
import 'package:dedecube_router/src/data/utilities/router_routes_extension.dart';
import 'package:dedecube_router/src/domain/contracts/router_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:dedecube_router/src/presentation/router_error_page.dart';
import 'package:go_router/go_router.dart';

/// Extension on [RouterContract] to initialize the [GoRouter] instance.
///
/// This extension provides the [initialize] getter that constructs and returns a
/// fully configured [GoRouter] using the routing configuration provided by the
/// [RouterContract]. The [GoRouter] is configured with the following settings:
/// - debugLogDiagnostics: Enables or disables diagnostic logging.
/// - initialLocation: Specifies the starting route location for the router.
/// - navigatorKey: Associates a key with the navigator for navigating through routes.
/// - routes: Converts each route element (regular routes and shell routes) to the appropriate
///   [RouteBase] implementation.
/// - redirect: Applies middleware to handle route redirection.
/// - observers: Includes a [RouterObserver] to monitor navigation events.
/// - errorBuilder: Provides a custom error page ([RouterErrorPage]) to handle routing errors.
extension RouterInitializeExtension on RouterContract {
  CustomRouter get initialize {
    return GoRouter(
      initialLocation: config.initialLocation,
      navigatorKey: config.navigatorKey,
      routes: config.toGoRouterRoutes(),
      observers: [RouterObserver(config)],
      errorBuilder: (context, state) =>
          config.errorPage ??
          RouterErrorPage(
            context: context,
            state: state,
          ),
    );
  }
}
