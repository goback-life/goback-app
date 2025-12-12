import 'package:flutter/widgets.dart' as widgets;
import 'package:go_router/go_router.dart';

/// Utility class for custom transition page builders.
class CustomTransitionPageBuilders {
  /// Fade transition builder using CustomTransitionPage.
  static widgets.Page fade(
    widgets.BuildContext context,
    GoRouterState state,
    widgets.Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          widgets.FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Signature for a custom transition page builder.
typedef CustomTransitionPageBuilder = widgets.Page Function(
  widgets.BuildContext context,
  GoRouterState state,
  widgets.Widget child,
);
