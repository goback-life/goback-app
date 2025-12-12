import 'package:dedecube_router/src/data/configs/router_config.dart';
import 'package:dedecube_router/src/data/enums/page_transition.dart';
import 'package:dedecube_router/src/data/utilities/custom_transition_page_builder.dart';
import 'package:dedecube_router/src/data/utilities/go_router_extra_mapping.dart';
import 'package:dedecube_router/src/data/utilities/router_middleware_pipeline.dart';
import 'package:dedecube_router/src/data/utilities/router_route_name_extension.dart';
import 'package:dedecube_router/src/domain/contracts/router_base_route_contract.dart';
import 'package:dedecube_router/src/domain/models/modal_settings.dart';
import 'package:dedecube_router/src/presentation/modal_page.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' as widgets;
import 'package:go_router/go_router.dart';

/// A contract defining the required route properties for an application.
///
/// The [RouterRouteContract] encapsulates the essential properties required for defining a route:
/// - [path]: The URL path corresponding to the route.
/// - [builder]: A function that builds the widget for the route using the provided BuildContext
///   and [GoRouterState].
///
/// It also provides helper methods:
/// - [toGoRoute]: Converts the RouterRouteContract entity into a [GoRoute] for use with the [GoRouter] package.
///   During conversion, it applies any defined middleware through a [RouterMiddlewarePipeline] to potentially
///   alter the navigation flow (e.g., for redirection).
///
/// Example usage:
/// ```dart
/// class HomeRoute extends RouterRouteContract<HomeRoute> with _$HomeRoute {
///   factory HomeRoute.fromJson(Map<String, dynamic> json) =>
///       _$HomeRouteFromJson(json);
///
///   const HomeRoute._();
///
///   const factory HomeRoute({
///     @Default(0) int id,
///   }) = _HomeRoute;
///
///   @override
///   String get path => '/home';
///
///   @override
///   List<Middleware> get middlewares => [
///         BiometricAuthEnabledMiddleware(),
///       ];
///
///   @override
///   Map<String, dynamic> get toMap => toJson();
///
///   @override
///   HomeRoute Function(Map<String, dynamic>) get fromMap => HomeRoute.fromJson;
///
///   @override
///   widgets.Widget buildPage(widgets.BuildContext context, HomeRoute routeData) {
///     return HomePage(id: routeData.id);
///   }
/// }
/// ```
///
/// When a navigation event occurs, the [builder] function uses the [fromMap] function to transform
/// any extra data passed along with the navigation event into the appropriate typed object, then
/// delegates widget building to [buildPage].
abstract class RouterRouteContract<T extends RouterRouteContract<T>>
    extends RouterBaseRouteContract<RouterRouteContract> {
  /// Creates a [RouterRouteContract] instance.
  const RouterRouteContract();

  @override
  RouteBase toRouteBase(RouterConfig config) {
    return toGoRoute(config);
  }

  /// The URL path corresponding to the route.
  @override
  String get path;

  /// The child routes that will be wrapped by this route.
  @override
  List<RouterBaseRouteContract> get routes => [];

  /// Function that converts the route instance to a JSON map.
  @override
  Map<String, dynamic> get toMap;

  /// Function that converts a JSON map to the route instance.
  @override
  T Function(Map<String, dynamic>) get fromMap;

  /// Indicates whether this route should be displayed as a modal.
  ///
  /// When true, the route will be wrapped in a [ModalPage].
  bool get isModal => false;

  /// Optional customization for modal presentation.
  ///
  /// Override this to customize how the modal is presented.
  /// Only used when [isModal] is true.
  ModalSettings get modalSettings => const ModalSettings();

  /// The type of page transition to use for this route.
  PageTransition get transitionType => PageTransition.material;

  /// Optional custom transition builder (only used if [transitionType] is [PageTransition.custom]).
  CustomTransitionPageBuilder? get customTransitionBuilder => null;

  /// Converts this [RouterRouteContract] into a widget.
  widgets.Widget buildPage(widgets.BuildContext context, T routeData);

  /// Default builder for a [GoRoute] that uses [fromMap] to transform extra data.
  ///
  /// This getter returns a function that:
  ///   1. Retrieves the extra data from the [GoRouterState]
  ///   2. Calls [buildPage] with the BuildContext and transformed route data.
  ///   3. If [isModal] is true, wraps the result in a [ModalPage].
  widgets.Page Function(widgets.BuildContext, GoRouterState) get builder =>
      (widgets.BuildContext context, GoRouterState state) {
        final routeData = state.getTypedExtra<T>(fromMap);
        final page = buildPage(context, routeData);

        if (isModal) {
          return ModalPage<void>(
            key: state.pageKey,
            isScrollControlled: modalSettings.isScrollControlled,
            isDismissible: modalSettings.isDismissible,
            backgroundColor: modalSettings.backgroundColor,
            modalBarrierColor: modalSettings.modalBarrierColor,
            child: page,
          );
        }

        switch (transitionType) {
          case PageTransition.noTransition:
            return NoTransitionPage<void>(
              name: name,
              key: state.pageKey,
              child: page,
            );
          case PageTransition.fade:
            return CustomTransitionPage<void>(
              name: name,
              key: state.pageKey,
              child: page,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      material.FadeTransition(opacity: animation, child: child),
            );
          case PageTransition.custom:
            if (customTransitionBuilder != null) {
              return customTransitionBuilder!(context, state, page);
            }
            // fallback to material if no custom builder provided
            return material.MaterialPage<void>(
              name: name,
              key: state.pageKey,
              child: page,
            );
          default:
            return material.MaterialPage<void>(
              name: name,
              key: state.pageKey,
              child: page,
            );
        }
      };

  /// Converts this [RouterRouteContract] into a [GoRoute] route.
  ///
  /// The resulting [GoRoute] encapsulates the display path, name, and builder for the route.
  /// If middlewares are defined, they are processed via [RouterMiddlewarePipeline] to determine if
  /// navigation should be intercepted and redirected.
  GoRoute toGoRoute(RouterConfig config) {
    return GoRoute(
      path: path,
      name: name,
      pageBuilder: builder,
      routes: routes.map((route) => route.toRouteBase(config)).toList(),
      redirect: (widgets.BuildContext context, GoRouterState state) async {
        if (config.middlewares.isNotEmpty) {
          final String? route =
              await RouterMiddlewarePipeline(config.middlewares)
                  .handle(context, state);
          if (route != null) {
            return route;
          }
        }
        if (middlewares.isNotEmpty && context.mounted) {
          return RouterMiddlewarePipeline(middlewares).handle(context, state);
        }
        return null;
      },
    );
  }

  @override
  String toString() => 'Routable(path: $path, name: $name)';
}
