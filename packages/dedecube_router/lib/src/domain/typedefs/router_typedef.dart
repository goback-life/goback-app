import 'package:dedecube_router/dedecube_router.dart';
import 'package:go_router/go_router.dart';

typedef Middleware = RouterMiddlewareContract;
typedef BaseRoutable<T extends RouterBaseRouteContract<T>>
    = RouterBaseRouteContract<T>;
typedef ShellRoutable<T extends RouterShellRouteContract<T>>
    = RouterShellRouteContract<T>;
typedef Routable<T extends RouterRouteContract<T>> = RouterRouteContract<T>;
typedef CustomRouter = GoRouter;
typedef CustomRouterState = GoRouterState;
typedef CustomShellRoute = ShellRoute;
