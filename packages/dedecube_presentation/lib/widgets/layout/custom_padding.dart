import 'package:flutter/material.dart';

/// A widget that adds padding to its child with flexible padding configuration.
///
/// This widget allows you to specify padding in multiple ways:
/// - Individual sides (top, bottom, left, right)
/// - Horizontal and vertical padding
/// - All sides at once
///
/// The final padding for each side is the sum of:
/// - The specific side value (if any)
/// - The horizontal/vertical value (if any)
/// - The all value (if any)
class CustomPadding extends StatelessWidget {
  /// Creates a CustomPadding widget.
  ///
  /// All padding values default to 0 if not specified.
  /// At least one padding value and/or a child should be provided.
  const CustomPadding({
    /// Padding for the top edge
    this.top = 0,

    /// Padding for the bottom edge
    this.bottom = 0,

    /// Padding for the left edge
    this.left = 0,

    /// Padding for the right edge
    this.right = 0,

    /// Padding for both left and right edges
    this.horizontal = 0,

    /// Padding for both top and bottom edges
    this.vertical = 0,

    /// Padding for all edges
    this.all = 0,

    /// The widget to be padded
    this.child,
    super.key,
  });

  /// Padding applied to all sides
  final double all;

  /// Padding applied to the bottom edge
  final double bottom;

  /// The widget to display inside the padding
  final Widget? child;

  /// Padding applied to both left and right edges
  final double horizontal;

  /// Padding applied to the left edge
  final double left;

  /// Padding applied to the right edge
  final double right;

  /// Padding applied to the top edge
  final double top;

  /// Padding applied to both top and bottom edges
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        all + horizontal + left,
        all + vertical + top,
        all + horizontal + right,
        all + vertical + bottom,
      ),
      child: child,
    );
  }
}
