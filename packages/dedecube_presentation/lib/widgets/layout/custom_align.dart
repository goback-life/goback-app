import 'package:flutter/material.dart';

/// Shorthand for the Align widget that takes a single line to align a child, e.g:
///
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///    return const CustomAlign.bottomRight(child: Icon(Icons.add));
///  }
/// ```
class CustomAlign extends StatelessWidget {
  CustomAlign({
    required this.child,
    super.key,
    double x = 0,
    double y = 0,
  }) : alignment = Alignment(x, y);

  const CustomAlign.center({
    required this.child,
    super.key,
  }) : alignment = Alignment.center;

  const CustomAlign.centerLeft({
    required this.child,
    super.key,
  }) : alignment = Alignment.centerLeft;

  const CustomAlign.centerRight({
    required this.child,
    super.key,
  }) : alignment = Alignment.centerRight;

  const CustomAlign.topCenter({
    required this.child,
    super.key,
  }) : alignment = Alignment.topCenter;

  const CustomAlign.bottomCenter({
    required this.child,
    super.key,
  }) : alignment = Alignment.bottomCenter;

  const CustomAlign.topLeft({
    required this.child,
    super.key,
  }) : alignment = Alignment.topLeft;

  const CustomAlign.bottomLeft({
    required this.child,
    super.key,
  }) : alignment = Alignment.bottomLeft;

  const CustomAlign.topRight({
    required this.child,
    super.key,
  }) : alignment = Alignment.topRight;

  const CustomAlign.bottomRight({
    required this.child,
    super.key,
  }) : alignment = Alignment.bottomRight;

  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: child,
    );
  }
}
