import 'package:dedecube_presentation/utilities/page_controller_safe.dart';
import 'package:flutter/material.dart';

/// A widget that reacts to continuous page position changes from a [PageController].
///
/// Unlike PageIndexReactor which only updates on whole page index changes,
/// this widget provides the exact decimal page position (e.g., 1.5 when halfway
/// between pages 1 and 2) and rebuilds continuously during page transitions.
///
/// This is particularly useful for creating smooth animations that respond to
/// page scrolling in real-time.
///
/// Example usage:
/// ```dart
/// PageReactor(
///   controller: _pageController,
///   builder: (context, child, page) {
///     return Transform.scale(
///       scale: 1.0 - (page - page.floor()).abs() * 0.3,
///       child: child,
///     );
///   },
/// )
/// ```
class PageReactor extends StatelessWidget {
  /// Creates a [PageReactor] widget.
  ///
  /// The [controller] is used to track continuous page position changes.
  /// The [builder] is called with the exact page position whenever it changes.
  /// An optional [child] widget can be provided that will be passed to the builder
  /// for more efficient rebuilds.
  const PageReactor({
    required this.controller,
    required this.builder,
    super.key,
    this.child,
  });

  final PageController controller;
  final Widget? child;
  final Widget Function(
    BuildContext context,
    Widget? child,
    double page,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (BuildContext context, Widget? child) {
        return builder(context, child, controller.safePage);
      },
    );
  }
}
