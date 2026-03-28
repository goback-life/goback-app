import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Triangle path matching the lockout button (viewBox 86x102).
///
/// Shared between [FeedLockoutButton] and [LockoutCutoutPainter].
Path lockoutTrianglePath(Size size) {
  final sx = size.width / 86.0;
  final sy = size.height / 102.0;

  return Path()
    ..moveTo(10.0244 * sx, 55.1414 * sy)
    ..cubicTo(
      1.42744 * sx, 48.7205 * sy,
      2.1564 * sx, 35.6124 * sy,
      11.4122 * sx, 30.1843 * sy,
    )
    ..lineTo(59.3289 * sx, 2.0836 * sy)
    ..cubicTo(
      69.3286 * sx, -3.7807 * sy,
      81.917 * sx, 3.43033 * sy,
      81.917 * sx, 15.0227 * sy,
    )
    ..lineTo(81.917 * sx, 78.9116 * sy)
    ..cubicTo(
      81.917 * sx, 91.2584 * sy,
      67.8333 * sx, 98.3179 * sy,
      57.941 * sx, 90.9295 * sy,
    )
    ..lineTo(10.0244 * sx, 55.1414 * sy)
    ..close();
}

/// Custom painter that draws a solid background with transparent cutouts
/// for the timer text, triangle, and completion text.
///
/// Uses [Canvas.saveLayer] + [BlendMode.dstOut] to punch holes through
/// the solid background, revealing the sky image beneath.
class LockoutCutoutPainter extends CustomPainter {
  LockoutCutoutPainter({
    required this.bgColor,
    required this.countdown,
    required this.triangleOpacity,
    required this.completionTextOpacity,
    required this.isComplete,
    this.gobackScore,
    this.lockoutDurationMinutes = 0,
  });

  final Color bgColor;
  final String countdown;
  final double triangleOpacity;
  final double completionTextOpacity;
  final bool isComplete;
  final int? gobackScore;
  final int lockoutDurationMinutes;

  /// Creates a foreground paint that punches holes via dstOut.
  Paint _holePaint([double opacity = 1.0]) => Paint()
    ..blendMode = BlendMode.dstOut
    ..color = Colors.white.withValues(alpha: opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.saveLayer(rect, Paint());

    // 1. Solid background fill
    canvas.drawRect(rect, Paint()..color = bgColor);

    // 2. Punch timer text hole
    if (countdown.isNotEmpty) {
      _paintTimerHole(canvas, size);
    }

    // 3. Punch triangle hole (fades out on completion)
    if (triangleOpacity > 0) {
      _paintTriangleHole(canvas, size);
    }

    // 4. Punch goback score hole
    if (isComplete && completionTextOpacity > 0 && gobackScore != null) {
      _paintScoreHole(canvas, size);
    }

    // 5. Punch completion text holes ("Share your goback" + "Skip")
    if (isComplete && completionTextOpacity > 0) {
      _paintCompletionHoles(canvas, size);
    }

    canvas.restore();
  }

  void _paintTimerHole(Canvas canvas, Size size) {
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

  void _paintTriangleHole(Canvas canvas, Size size) {
    final triangleH = size.width * 0.35;
    final triangleW = triangleH * 86 / 102;
    final triangleX = (size.width - triangleW) / 2;
    final triangleY = size.height - size.height * 0.08 - triangleH;
    final path = lockoutTrianglePath(Size(triangleW, triangleH));

    canvas.save();
    canvas.translate(triangleX, triangleY);
    canvas.drawPath(path, _holePaint(triangleOpacity));
    canvas.restore();
  }

  void _paintScoreHole(Canvas canvas, Size size) {
    final dH = lockoutDurationMinutes ~/ 60;
    final dM = lockoutDurationMinutes % 60;
    final durationStr = '$dH:${dM.toString().padLeft(2, '0')}';
    final scoreStr = '$gobackScore | $durationStr';

    final scoreTp = TextPainter(
      text: TextSpan(
        text: scoreStr,
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontWeight: FontWeight.w500,
          fontSize: 28,
          letterSpacing: 1.0,
          foreground: _holePaint(completionTextOpacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final scoreY = size.height * 0.68;
    scoreTp.paint(
      canvas,
      Offset((size.width - scoreTp.width) / 2, scoreY),
    );

    // Label: "score / 100 | time"
    final labelTp = TextPainter(
      text: TextSpan(
        text: 'score / 100 | time',
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          letterSpacing: 0.5,
          foreground: _holePaint(completionTextOpacity * 0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(
      canvas,
      Offset((size.width - labelTp.width) / 2, scoreY + scoreTp.height + 6),
    );
  }

  void _paintCompletionHoles(Canvas canvas, Size size) {
    final shareY = size.height * 0.78;
    final skipY = size.height * 0.87;

    final shareTp = TextPainter(
      text: TextSpan(
        text: 'Share your goback',
        style: TextStyle(
          fontFamily: MainFontFamilies.lilitaOne,
          fontSize: 48,
          foreground: _holePaint(completionTextOpacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final skipTp = TextPainter(
      text: TextSpan(
        text: 'Skip',
        style: TextStyle(
          fontFamily: MainFontFamilies.quicksand,
          fontWeight: FontWeight.w500,
          fontSize: 24,
          foreground: _holePaint(completionTextOpacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    shareTp.paint(
      canvas,
      Offset((size.width - shareTp.width) / 2, shareY),
    );
    skipTp.paint(
      canvas,
      Offset((size.width - skipTp.width) / 2, skipY),
    );
  }

  @override
  bool shouldRepaint(covariant LockoutCutoutPainter oldDelegate) =>
      oldDelegate.bgColor != bgColor ||
      oldDelegate.countdown != countdown ||
      oldDelegate.triangleOpacity != triangleOpacity ||
      oldDelegate.completionTextOpacity != completionTextOpacity ||
      oldDelegate.isComplete != isComplete ||
      oldDelegate.gobackScore != gobackScore ||
      oldDelegate.lockoutDurationMinutes != lockoutDurationMinutes;
}
