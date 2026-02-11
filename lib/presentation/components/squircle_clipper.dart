import 'package:flutter/widgets.dart';

/// Clips to a squircle matching the Figma V1 design (node 72-590).
///
/// Uses the exact cubic-bezier corner curves exported from Figma rather
/// than a superellipse approximation.  Corner radius is 15% of the
/// shorter side, with Figma-style smoothing (control point at 2.6475%).
class SquircleClipper extends CustomClipper<Path> {
  const SquircleClipper();

  @override
  Path getClip(Size size) => squirclePath(size);

  @override
  bool shouldReclip(SquircleClipper oldClipper) => false;

  /// Generates a squircle path scaled to [size] using Figma's cubic
  /// bezier corners.  Proportions taken from Figma SVG (250×250 viewBox,
  /// corner radius 37.5, control offset 6.61875).
  static Path squirclePath(Size size) {
    final w = size.width;
    final h = size.height;

    // Corner radius & control-point offset as fractions of each axis.
    // From Figma: r = 37.5/250 = 0.15, cp = 6.61875/250 ≈ 0.026475
    final rx = w * 0.15;
    final cx = w * 0.026475;
    final ry = h * 0.15;
    final cy = h * 0.026475;

    return Path()
      // Start at left edge, below top-left corner
      ..moveTo(0, ry)
      // Top-left corner
      ..cubicTo(0, cy, cx, 0, rx, 0)
      // Top edge
      ..lineTo(w - rx, 0)
      // Top-right corner
      ..cubicTo(w - cx, 0, w, cy, w, ry)
      // Right edge
      ..lineTo(w, h - ry)
      // Bottom-right corner
      ..cubicTo(w, h - cy, w - cx, h, w - rx, h)
      // Bottom edge
      ..lineTo(rx, h)
      // Bottom-left corner
      ..cubicTo(cx, h, 0, h - cy, 0, h - ry)
      // Left edge back to start
      ..close();
  }
}

/// Convenience widget that clips its child to the Figma squircle.
class ClipSquircle extends StatelessWidget {
  const ClipSquircle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const SquircleClipper(),
      child: child,
    );
  }
}
