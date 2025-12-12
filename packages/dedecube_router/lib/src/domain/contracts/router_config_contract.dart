import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

typedef LogRouterActionCallback = void Function(
    String action, BaseRoutable? route);

/// A contract defining the required router configurations for an application.
abstract class RouterConfigContract {
  /// The initial route location for the application.
  String get initialLocation;

  /// The key associated with the navigator, used for managing the navigation stack.
  widgets.GlobalKey<widgets.NavigatorState>? get navigatorKey;

  /// The list of [BaseRoutable] elements representing the available routes.
  List<BaseRoutable> get routes;

  /// The list of [Middleware] elements representing the middleware to be applied to the routes.
  List<Middleware> get middlewares;

  /// A flag indicating whether logging is enabled for router actions.
  bool get isLogEnabled;

  /// A callback function that can be used to log router actions.
  LogRouterActionCallback? get logRouterAction;

  /// The widget displayed when an error occurs during app initialization.
  /// If not set, a default error widget will be used.
  widgets.Widget? errorPage;
}
