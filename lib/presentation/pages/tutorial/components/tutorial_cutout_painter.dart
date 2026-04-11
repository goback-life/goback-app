import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Draws a solid background with timer text + triangle cutouts,
/// adapted from [ManualLockoutView._CutoutPainter].
///
/// No score, no completion text — tutorial only shows countdown.
class TutorialCutoutPainter extends CustomPainter {
  TutorialCutoutPainter({required this.bgColor, required this.countdown});

  final Color bgColor;
  final String countdown;

  Paint _holePaint([double opacity = 1.0]) => Paint()
    ..blendMode = BlendMode.dstOut
    ..color = Colors.white.withValues(alpha: opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.saveLayer(rect, Paint());

    // 1. Solid background
    canvas.drawRect(rect, Paint()..color = bgColor);

    // 2. Timer text cutout
    if (countdown.isNotEmpty) {
      final timerFontSize = size.width * 0.8;
      final timerLetterSpacing = size.width * -0.04;
      final tp = TextPainter(
        text: TextSpan(
          text: countdown,
          style: TextStyle(
            fontFamily: MainFontFamilies.lilitaOne,
            fontSize: timerFontSize,
            letterSpacing: timerLetterSpacing,
            height: 1.0,
            foreground: _holePaint(),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final targetW = size.width * 0.95;
      final scale = targetW / tp.width;
      final timerY = size.height * 0.35;
      final timerX = (size.width - tp.width * scale) / 2;

      canvas.save();
      canvas.translate(timerX, timerY);
      canvas.scale(scale);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // 3. Triangle cutout
    final triangleH = size.width * 0.35;
    final triangleW = triangleH * 86 / 102;
    final triangleX = (size.width - triangleW) / 2;
    final triangleY = size.height - size.height * 0.08 - triangleH;
    final path = _trianglePath(Size(triangleW, triangleH));

    canvas.save();
    canvas.translate(triangleX, triangleY);
    canvas.drawPath(path, _holePaint());
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TutorialCutoutPainter old) =>
      old.bgColor != bgColor || old.countdown != countdown;
}

Path _trianglePath(Size size) {
  final sx = size.width / 86.0;
  final sy = size.height / 102.0;

  return Path()
    ..moveTo(10.0244 * sx, 55.1414 * sy)
    ..cubicTo(
      1.42744 * sx,
      48.7205 * sy,
      2.1564 * sx,
      35.6124 * sy,
      11.4122 * sx,
      30.1843 * sy,
    )
    ..lineTo(59.3289 * sx, 2.0836 * sy)
    ..cubicTo(
      69.3286 * sx,
      -3.7807 * sy,
      81.917 * sx,
      3.43033 * sy,
      81.917 * sx,
      15.0227 * sy,
    )
    ..lineTo(81.917 * sx, 78.9116 * sy)
    ..cubicTo(
      81.917 * sx,
      91.2584 * sy,
      67.8333 * sx,
      98.3179 * sy,
      57.941 * sx,
      90.9295 * sy,
    )
    ..lineTo(10.0244 * sx, 55.1414 * sy)
    ..close();
}
