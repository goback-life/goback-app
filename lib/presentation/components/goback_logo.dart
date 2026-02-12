import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// The goback wordmark logo: "goback" in Lilita One + left-pointing accent
/// triangle. Scales uniformly via [fontSize].
class GobackLogo extends StatelessWidget {
  const GobackLogo({
    super.key,
    this.fontSize = 32,
    this.textColor = MainColors.white,
    this.triangleColor = MainColors.accent,
  });

  final double fontSize;
  final Color textColor;
  final Color triangleColor;

  @override
  Widget build(BuildContext context) {
    final triangleSize = fontSize * 0.55;
    final gap = fontSize * 0.15;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'goback',
          style: TextStyle(
            fontFamily: MainFontFamilies.lilitaOne,
            fontSize: fontSize,
            color: textColor,
            height: 1.1,
          ),
        ),
        SizedBox(width: gap),
        CustomPaint(
          size: Size(triangleSize, triangleSize),
          painter: _LeftTrianglePainter(color: triangleColor),
        ),
      ],
    );
  }
}

class _LeftTrianglePainter extends CustomPainter {
  const _LeftTrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Left-pointing triangle with rounded corners
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    // Round the corners by drawing with a rounded stroke then filling
    final rrPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      _roundedTrianglePath(size),
      rrPaint,
    );
  }

  Path _roundedTrianglePath(Size size) {
    final r = size.width * 0.12; // corner rounding radius
    final w = size.width;
    final h = size.height;

    // Three vertices: left tip, top-right, bottom-right
    final tip = Offset(0, h * 0.5);
    final topRight = Offset(w, 0);
    final bottomRight = Offset(w, h);

    final path = Path();

    // Move to a point offset from the tip along the top edge
    path.moveTo(
      tip.dx + r * 1.5,
      tip.dy - r * 0.75,
    );

    // Line to top-right corner, then round it
    path.lineTo(topRight.dx - r, topRight.dy);
    path.quadraticBezierTo(topRight.dx, topRight.dy, topRight.dx, topRight.dy + r);

    // Line to bottom-right corner, then round it
    path.lineTo(bottomRight.dx, bottomRight.dy - r);
    path.quadraticBezierTo(
      bottomRight.dx, bottomRight.dy, bottomRight.dx - r, bottomRight.dy,
    );

    // Line back to tip, round it
    path.lineTo(tip.dx + r * 1.5, tip.dy + r * 0.75);
    path.quadraticBezierTo(tip.dx, tip.dy, tip.dx + r * 1.5, tip.dy - r * 0.75);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _LeftTrianglePainter oldDelegate) =>
      color != oldDelegate.color;
}
