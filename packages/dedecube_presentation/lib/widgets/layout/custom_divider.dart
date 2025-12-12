import 'package:dedecube_presentation/utilities/build_context.dart';
import 'package:flutter/material.dart';

/// A customizable divider widget that can be oriented horizontally or vertically.
///
/// This widget creates a line with customizable thickness, color, and margins.
/// It can be used to visually separate content in both horizontal and vertical layouts.
class CustomDivider extends StatelessWidget {
  const CustomDivider({
    super.key,
    this.thickness = 1,
    this.cross = 0,
    this.main = 0,
    this.start = 0,
    this.end = 0,
    this.before = 0,
    this.after = 0,
    this.all = 0,
    this.color,
    this.axis = Axis.horizontal,
  });

  /// The thickness of the divider line.
  final double thickness;

  /// Margin in the cross axis direction (perpendicular to the divider).
  final double cross;

  /// Margin in the main axis direction (parallel to the divider).
  final double main;

  /// Starting margin (left for horizontal, top for vertical).
  final double start;

  /// Ending margin (right for horizontal, bottom for vertical).
  final double end;

  /// Margin before the divider in the main axis.
  final double before;

  /// Margin after the divider in the main axis.
  final double after;

  /// Uniform margin on all sides.
  final double all;

  /// The color of the divider. If null, uses the theme's divider color.
  final Color? color;

  /// The axis along which the divider extends.
  /// [Axis.horizontal] creates a horizontal line, [Axis.vertical] creates a vertical line.
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? context.theme.dividerTheme.color,
      margin: switch (axis) {
        Axis.horizontal => EdgeInsets.fromLTRB(
            start + cross + all,
            before + main + all,
            end + cross + all,
            after + main + all,
          ),
        Axis.vertical => EdgeInsets.fromLTRB(
            before + main + all,
            start + cross + all,
            after + main + all,
            end + cross + all,
          ),
      },
      width: switch (axis) {
        Axis.horizontal => double.infinity,
        Axis.vertical => thickness,
      },
      height: switch (axis) {
        Axis.horizontal => thickness,
        Axis.vertical => double.infinity,
      },
    );
  }
}
