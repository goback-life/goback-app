import 'package:dedecube_router/src/data/configs/router_config.dart';
import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';
import 'package:go_router/go_router.dart';

/// A base contract defining the fundamental properties for all route types in an application.
///
/// The [RouterBaseRouteContract] establishes the core interface that all route types must implement,
/// enabling a unified approach to route definition and conversion. It defines:
/// - [path]: The URL path corresponding to the route.
/// - [middlewares]: Optional interceptors that can redirect navigation or perform side effects.
/// - [routes]: Child routes for nested navigation structures.
/// - [toRouteBase]: Conversion method to transform the route into a GoRouter-compatible format.
///
/// This contract serves as the foundation for more specific route allowing them to be used interchangeably in navigation configurations.
abstract class RouterBaseRouteContract<T extends RouterBaseRouteContract<T>> {
  const RouterBaseRouteContract();

  /// Converts this route to a RouteBase for use with GoRouter.
  RouteBase toRouteBase(RouterConfig config);

  /// The URL path corresponding to the route.
  String get path;

  /// A list of middlewares to be applied to this route.
  List<Middleware> get middlewares => [];

  /// The child routes that will be wrapped by this shell route.
  List<BaseRoutable> get routes => [];

  /// Function that converts the route instance to a JSON map.
  Map<String, dynamic> get toMap;

  /// Function that converts a JSON map to the route instance.
  T Function(Map<String, dynamic>) get fromMap;
}
