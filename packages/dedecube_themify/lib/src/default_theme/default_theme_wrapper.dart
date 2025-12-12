import 'package:dedecube_themify/src/data/utilities/themify_theme_extension.dart';
import 'package:dedecube_themify/src/default_theme/default_theme.dart';
import 'package:flutter/material.dart';

/// A widget that forces the use of the default theme for its child widget tree.
///
/// The [DefaultThemeWrapper] encapsulates its child widgets in a [Theme] widget
/// using the [DefaultTheme]'s configured theme data. This is useful when you
/// want a specific screen or part of your application to always display using the
/// default theme, overriding any custom theme set in the startup configuration.
///
/// The [builder] callback provides the child widget tree that will receive the default theme.
class DefaultThemeWrapper extends StatelessWidget {
  const DefaultThemeWrapper({required this.builder, super.key});
  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DefaultTheme().configuredThemeData,
      child: Builder(
        builder: (context) {
          return builder(context);
        },
      ),
    );
  }
}
