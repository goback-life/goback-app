import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Clips to a superellipse (squircle) matching iOS/Figma smooth corners.
///
/// Uses the formula |x/a|^n + |y/b|^n = 1 where n defaults to 5,
/// closely matching Apple's continuous corner curve.
class SquircleClipper extends CustomClipper<Path> {
  const SquircleClipper({this.exponent = 5.0});

  /// The superellipse exponent. Higher values = squarer corners.
  /// 2.0 = ellipse, 5.0 = iOS smooth corners, infinity = rectangle.
  final double exponent;

  @override
  Path getClip(Size size) => _superellipsePath(size, exponent);

  @override
  bool shouldReclip(SquircleClipper oldClipper) =>
      oldClipper.exponent != exponent;

  /// Generates a superellipse path centered in [size].
  static Path _superellipsePath(Size size, double n) {
    final a = size.width / 2;
    final b = size.height / 2;
    const steps = 200;
    final points = <Offset>[];

    for (var i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * math.pi;
      final cosT = math.cos(t);
      final sinT = math.sin(t);

      final x = a * math.pow(cosT.abs(), 2 / n) * cosT.sign + a;
      final y = b * math.pow(sinT.abs(), 2 / n) * sinT.sign + b;
      points.add(Offset(x, y));
    }

    final path = Path()..addPolygon(points, true);
    return path;
  }
}

/// Convenience widget that clips its child to a superellipse (squircle).
class ClipSquircle extends StatelessWidget {
  const ClipSquircle({
    super.key,
    required this.child,
    this.exponent = 5.0,
  });

  final Widget child;
  final double exponent;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: SquircleClipper(exponent: exponent),
      child: child,
    );
  }
}
