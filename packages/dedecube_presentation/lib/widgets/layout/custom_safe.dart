import 'package:flutter/material.dart';

/// A widget that wraps SafeArea to provide easy access to safe area padding
/// on specific edges of the screen.
///
/// This widget is useful for ensuring content is not obscured by system UI elements
/// such as the status bar, notches, or navigation bars.
///
/// When a keyboard is visible on mobile, MediaQuery.paddingOf(context) usually returns zero
///  on the bottom since the bottom padding would not cover anything on the screen.
/// Because of that, your view may jump up and down a bit when opening / closing the keyboard
///  if the entire view depends on the padding put on the bottom (usually when using flexible column layouts)
/// To avoid that, set ```CustomSafe.maintainBottomSafeOnKeyboardVisible``` to switch to
///  using MediaQuery.viewPaddingOf(context) only on the bottom side instead.
class CustomSafe extends StatelessWidget {
  /// Creates a CustomSafe widget with customizable safe area padding.
  ///
  /// Use [applyTop], [applyBottom], [applyLeft], and [applyRight] to specify
  /// which edges should respect the safe area.
  ///
  /// Set [maintainBottomSafeOnKeyboardVisible] to true to maintain bottom padding
  /// when the keyboard is visible.
  const CustomSafe({
    required this.child,
    super.key,
    this.applyTop = false,
    this.applyBottom = false,
    this.applyLeft = false,
    this.applyRight = false,
    this.maintainBottomSafeOnKeyboardVisible = false,
  });

  /// Creates a CustomSafe widget with no safe area padding on any edge.
  const CustomSafe.none({
    required this.child,
    super.key,
  })  : applyTop = false,
        applyBottom = false,
        applyLeft = false,
        applyRight = false,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Creates a CustomSafe widget with safe area padding only at the top.
  const CustomSafe.top({
    required this.child,
    super.key,
  })  : applyTop = true,
        applyBottom = false,
        applyLeft = false,
        applyRight = false,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Creates a CustomSafe widget with safe area padding only at the bottom.
  const CustomSafe.bottom({
    required this.child,
    super.key,
    this.maintainBottomSafeOnKeyboardVisible = false,
  })  : applyTop = false,
        applyBottom = true,
        applyLeft = false,
        applyRight = false;

  /// Creates a CustomSafe widget with safe area padding only on the left side.
  const CustomSafe.left({
    required this.child,
    super.key,
  })  : applyTop = false,
        applyBottom = false,
        applyLeft = true,
        applyRight = false,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Creates a CustomSafe widget with safe area padding only on the right side.
  const CustomSafe.right({
    required this.child,
    super.key,
  })  : applyTop = false,
        applyBottom = false,
        applyLeft = false,
        applyRight = true,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Creates a CustomSafe widget with safe area padding on both the top and bottom.
  const CustomSafe.vertical({
    required this.child,
    super.key,
    this.maintainBottomSafeOnKeyboardVisible = false,
  })  : applyTop = true,
        applyBottom = true,
        applyLeft = false,
        applyRight = false;

  /// Creates a CustomSafe widget with safe area padding on both the left and right sides.
  const CustomSafe.horizontal({
    required this.child,
    super.key,
  })  : applyTop = false,
        applyBottom = false,
        applyLeft = true,
        applyRight = true,
        maintainBottomSafeOnKeyboardVisible = false;

  /// Creates a CustomSafe widget with safe area padding on all edges.
  const CustomSafe.all({
    required this.child,
    super.key,
    this.maintainBottomSafeOnKeyboardVisible = false,
  })  : applyTop = true,
        applyBottom = true,
        applyLeft = true,
        applyRight = true;

  /// Whether to apply safe area padding at the bottom edge.
  final bool applyBottom;

  /// Whether to apply safe area padding at the left edge.
  final bool applyLeft;

  /// Whether to apply safe area padding at the right edge.
  final bool applyRight;

  /// Whether to apply safe area padding at the top edge.
  final bool applyTop;

  /// Whether to maintain bottom padding when the keyboard is visible.
  final bool maintainBottomSafeOnKeyboardVisible;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: applyTop,
      bottom: applyBottom,
      left: applyLeft,
      right: applyRight,
      maintainBottomViewPadding: maintainBottomSafeOnKeyboardVisible,
      child: child,
    );
  }
}
