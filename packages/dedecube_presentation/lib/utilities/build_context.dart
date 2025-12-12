import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  /// Returns the current theme configuration.
  ThemeData get theme => Theme.of(this);

  /// Returns the current media query data which contains info about screen metrics.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns the safe area padding, with an option to maintain bottom padding when keyboard is visible.
  ///
  /// [maintainBottomIfKeyboardVisible] - If true, preserves the bottom padding even when keyboard appears.
  EdgeInsets safe({bool maintainBottomIfKeyboardVisible = false}) {
    if (maintainBottomIfKeyboardVisible) {
      return MediaQuery.paddingOf(this)
          .copyWith(bottom: MediaQuery.viewPaddingOf(this).bottom);
    }
    return MediaQuery.paddingOf(this);
  }

  /// Returns the nearest ancestor [ScaffoldState].
  ScaffoldState get scaffold => Scaffold.of(this);

  /// Returns the nearest ancestor [NavigatorState].
  NavigatorState get navigator => Navigator.of(this);

  /// Unfocuses the current focus scope if it has focus but isn't the primary focus.
  /// Useful for dismissing the keyboard when tapping outside of a text field.
  void unfocus() {
    final FocusScopeNode currentScope = FocusScope.of(this);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
      currentScope.unfocus();
    }
  }

  /// Shows a Material dialog above the current contents of the app.
  ///
  /// Exposes the same optional and default values of the method it's short for
  Future<T?> showDialog<T>(
    Widget dialog, {
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
  }) =>
      mat.showDialog<T>(
        context: this,
        builder: (_) => dialog,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior,
      );

  /// Shows a modal material design bottom sheet.
  ///
  /// Exposes the same optional and default values of the method it's short for
  Future<T?> showModalBottomSheet<T>(
    Widget sheet, {
    Color? backgroundColor,
    String? barrierLabel,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    double scrollControlDisabledMaxHeightRatio = 9 / 16,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool? showDragHandle,
    bool useSafeArea = false,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
    AnimationStyle? sheetAnimationStyle,
  }) =>
      mat.showModalBottomSheet<T>(
        context: this,
        builder: (_) => sheet,
        backgroundColor: backgroundColor,
        barrierLabel: barrierLabel,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        isScrollControlled: isScrollControlled,
        scrollControlDisabledMaxHeightRatio:
            scrollControlDisabledMaxHeightRatio,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        showDragHandle: showDragHandle,
        useSafeArea: useSafeArea,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
        anchorPoint: anchorPoint,
        sheetAnimationStyle: sheetAnimationStyle,
      );
}
