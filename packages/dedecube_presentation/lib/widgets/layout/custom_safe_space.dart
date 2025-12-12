import 'package:flutter/material.dart';

/// A widget that wraps [SafeArea] and [SizedBox] to provide and empty safe
/// space to pad different sides of the screen. Useful to put at the start or end of rows or columns.
///
/// This widget helps ensure that content is not obscured by system UI elements
/// like the status bar, notches, or navigation bars.
///
/// The [width] and [height] parameters can be used to add additional padding beyond the safe area.
class CustomSafeSpace extends StatelessWidget {
  /// Creates a CustomSafeSpace that only applies top safe area padding.
  const CustomSafeSpace.top({
    super.key,
    this.height = 0,
  })  : applyTop = true,
        applyBottom = false,
        applyLeft = false,
        applyRight = false,
        width = 0,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Creates a CustomSafeSpace that only applies bottom safe area padding.
  ///
  /// [maintainBottomSafeOnKeyboardVisible] determines whether to maintain the bottom
  /// padding when the keyboard is visible.
  const CustomSafeSpace.bottom({
    super.key,
    this.height = 0,
    this.maintainBottomSafeOnKeyboardVisible = false,
  })  : applyTop = false,
        applyBottom = true,
        applyLeft = false,
        width = 0,
        applyRight = false;

  /// Creates a CustomSafeSpace that only applies left safe area padding.
  const CustomSafeSpace.left({
    super.key,
    this.width = 0,
  })  : applyTop = false,
        applyBottom = false,
        applyLeft = true,
        applyRight = false,
        height = 0,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Creates a CustomSafeSpace that only applies right safe area padding.
  const CustomSafeSpace.right({
    super.key,
    this.width = 0,
  })  : applyTop = false,
        applyBottom = false,
        applyLeft = false,
        applyRight = true,
        height = 0,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Whether to apply bottom safe area padding.
  final bool applyBottom;

  /// Whether to apply left safe area padding.
  final bool applyLeft;

  /// Whether to apply right safe area padding.
  final bool applyRight;

  /// Whether to apply top safe area padding.
  final bool applyTop;

  /// Additional height to add beyond the safe area.
  final double height;

  /// Additional width to add beyond the safe area.
  final double width;

  /// Whether to maintain bottom padding when the keyboard is visible.
  final bool maintainBottomSafeOnKeyboardVisible;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: applyTop,
      bottom: applyBottom,
      left: applyLeft,
      right: applyRight,
      maintainBottomViewPadding: maintainBottomSafeOnKeyboardVisible,
      child: SizedBox(height: height, width: width),
    );
  }
}
