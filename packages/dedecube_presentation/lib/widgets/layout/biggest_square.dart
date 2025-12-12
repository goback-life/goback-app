import 'dart:math';

import 'package:flutter/material.dart';

/// A widget that creates the largest possible square within its constraints.
///
/// This widget will determine the maximum square size that can fit within the given
/// layout constraints by taking the minimum of the available width and height.
///
/// Example usage:
/// ```dart
/// BiggestSquare(
///   builder: (context, dimension) => Center(
///     child: Icon(Icons.add),
///   ),
/// )
/// ```
///
/// If both constraints are infinite or NaN, it will use [fallbackSize] as the dimension.
///
/// The [shrink] parameter determines whether the resulting widget should be wrapped
/// in a [SizedBox.square] with the calculated dimension. When [shrink] is true,
/// the builder result is returned directly without enforcing the square size.
class BiggestSquare extends StatelessWidget {
  const BiggestSquare({
    required this.builder,
    super.key,
    this.fallbackSize = 50,
    this.shrink = false,
  });

  final Widget Function(BuildContext context, double dimension) builder;

  /// if the widget is unconstrained on all directions, this will be the size assigned to the square
  final double fallbackSize;

  /// if true, the builder will NOT be wrapped by a [SizedBox.square()] that matches the square dimension found
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double dimension = min(constraints.maxHeight, constraints.maxWidth);
        if (dimension.isNaN || dimension.isInfinite) {
          dimension = fallbackSize;
        }
        if (shrink) {
          return builder(context, dimension);
        }
        return SizedBox.square(
          dimension: dimension,
          child: builder(context, dimension),
        );
      },
    );
  }
}
