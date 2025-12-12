import 'package:dedecube_router/src/domain/contracts/router_config_contract.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:flutter/widgets.dart' as widgets;

class RouterConfig implements RouterConfigContract {
  RouterConfig({
    String? initialLocation,
    List<BaseRoutable>? routes,
    List<Middleware>? middlewares,
    this.navigatorKey,
    this.errorPage,
    bool? isLogEnabled,
    this.logRouterAction,
  })  : initialLocation = initialLocation ?? _initialLocation,
        routes = routes ?? <BaseRoutable>[],
        isLogEnabled = isLogEnabled ?? false,
        middlewares = middlewares ?? <Middleware>[];

  static const String _initialLocation = '/';

  @override
  final String initialLocation;

  @override
  final widgets.GlobalKey<widgets.NavigatorState>? navigatorKey;

  @override
  final List<BaseRoutable> routes;

  @override
  final List<Middleware> middlewares;

  @override
  widgets.Widget? errorPage;

  @override
  final bool isLogEnabled;

  @override
  final LogRouterActionCallback? logRouterAction;
}
