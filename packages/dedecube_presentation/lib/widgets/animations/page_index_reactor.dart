import 'package:dedecube_presentation/utilities/page_controller_safe.dart';
import 'package:flutter/material.dart';

/// A widget that reacts to page index changes from a [PageController].
///
/// This widget listens to a [PageController] and provides the current page index
/// as an integer value to its builder function, triggering rebuilds only when
/// the rounded page index changes.
///
/// Example usage:
/// ```dart
/// PageIndexReactor(
///   controller: _pageController,
///   builder: (context, child, page) {
///     return Text('Current page: $page');
///   },
/// )
/// ```
class PageIndexReactor extends StatefulWidget {
  /// Creates a [PageIndexReactor] widget.
  ///
  /// The [controller] is used to track page changes.
  /// The [builder] is called with the current page index whenever it changes.
  /// An optional [child] widget can be provided that will be passed to the builder
  /// for more efficient rebuilds.
  const PageIndexReactor({
    required this.controller,
    required this.builder,
    super.key,
    this.child,
  });

  /// The [PageController] to track for page changes.
  final PageController controller;

  /// An optional child widget that will be passed to the [builder].
  final Widget? child;

  /// Builder function that constructs the widget tree based on the current page index.
  ///
  /// The context and [child] parameters are provided for building the widget.
  /// The page parameter represents the current integer page index.
  final Widget Function(
    BuildContext context,
    Widget? child,
    int page,
  ) builder;

  @override
  State<PageIndexReactor> createState() => _PageIndexReactorState();
}

class _PageIndexReactorState extends State<PageIndexReactor> {
  late int page = widget.controller.safePage.round();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  void listener() {
    handleChange(widget.controller.safePage);
  }

  void handleChange(double newValue) {
    final int rounded = newValue.round();
    if (rounded != page) {
      setState(() {
        page = rounded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child, page);
  }
}
