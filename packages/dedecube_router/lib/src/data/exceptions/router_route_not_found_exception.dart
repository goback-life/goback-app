import 'package:dedecube_router/src/domain/typedefs/router_typedef.dart';

class RouterRouteNotFoundException implements Exception {
  RouterRouteNotFoundException(this.route);
  final BaseRoutable route;

  @override
  String toString() =>
      'RouterRouteNotFoundException: Unable to retrieve the route $route.';
}
