import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Maximum lockout duration the ring represents (one full rotation).
const kMaxLockoutDuration = Duration(hours: 10);
const _kMaxMinutes = 600; // 10 * 60
const _kSnapMinutes = 15;
const _kTrackWidth = 14.0;
const kThumbRadius = 15.0;
const _kGlowBlur = 4.0;

// ---------------------------------------------------------------------------
// Pure math helpers (tested in unit tests)
// ---------------------------------------------------------------------------

/// Converts a [Duration] to the sweep angle in radians (0 → 2π).
double durationToSweepAngle(Duration duration) {
  final minutes = duration.inMinutes.clamp(0, _kMaxMinutes);
  return (minutes / _kMaxMinutes) * 2 * pi;
}

/// Converts a sweep angle in radians (0 → 2π) to a [Duration].
Duration angleToDuration(double angle) {
  final clamped = angle.clamp(0.0, 2 * pi);
  final minutes = (clamped / (2 * pi) * _kMaxMinutes).round();
  return Duration(minutes: minutes);
}

/// Snaps a duration to the nearest 15-minute increment, clamped to
/// [minMinutes]..[_kMaxMinutes].
Duration snapDuration(Duration duration, {int minMinutes = 0}) {
  final raw = duration.inMinutes.clamp(0, _kMaxMinutes);
  final snapped = ((raw + _kSnapMinutes ~/ 2) ~/ _kSnapMinutes) * _kSnapMinutes;
  final clamped = snapped.clamp(minMinutes, _kMaxMinutes);
  return Duration(minutes: clamped);
}

/// Returns the clockwise angle in radians from 12-o'clock (0 → 2π)
/// for a point relative to [cx],[cy].
double polarAngleFromPoint(double px, double py, double cx, double cy) {
  final raw = atan2(px - cx, cy - py);
  return raw < 0 ? raw + 2 * pi : raw;
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class LockoutRingPainter extends CustomPainter {
  LockoutRingPainter({
    required this.sweepAngle,
    required this.skyImage,
    required this.trackColor,
    required this.glowColor,
    required this.tickColor,
    required this.thumbColor,
  });

  final double sweepAngle;
  final ui.Image? skyImage;
  final Color trackColor;
  final Color glowColor;
  final Color tickColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - kThumbRadius;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2; // 12 o'clock

    _drawTrack(canvas, rect);
    _drawTicks(canvas, center, radius);

    if (sweepAngle > 0) {
      _drawGlow(canvas, rect, startAngle);
      _drawSkyArc(canvas, rect, startAngle);
    }

    _drawThumb(canvas, center, radius, startAngle);
  }

  void _drawTrack(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kTrackWidth
      ..color = trackColor;
    canvas.drawCircle(rect.center, rect.width / 2, paint);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = tickColor;

    const tickLength = 8.0;
    for (var i = 0; i < 4; i++) {
      final angle = -pi / 2 + (i * pi / 2);
      final outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );
      canvas.drawLine(outerPoint, innerPoint, paint);
    }
  }

  void _drawGlow(Canvas canvas, Rect rect, double startAngle) {
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kTrackWidth + 6
      ..strokeCap = StrokeCap.round
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _kGlowBlur);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
  }

  void _drawSkyArc(Canvas canvas, Rect rect, double startAngle) {
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kTrackWidth
      ..strokeCap = StrokeCap.round;

    if (skyImage != null) {
      final scaleX = rect.width / skyImage!.width;
      final scaleY = rect.height / skyImage!.height;
      final scale = max(scaleX, scaleY);
      final matrix = Matrix4.identity()
        ..translate(rect.left, rect.top)
        ..scale(scale, scale);

      arcPaint.shader = ImageShader(
        skyImage!,
        TileMode.clamp,
        TileMode.clamp,
        matrix.storage,
      );
    } else {
      arcPaint.color = thumbColor;
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  void _drawThumb(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
  ) {
    final thumbAngle = startAngle + sweepAngle;
    final thumbCenter = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    final thumbPaint = Paint()..color = thumbColor;
    canvas.drawCircle(thumbCenter, kThumbRadius, thumbPaint);

    final sheenPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(thumbCenter.dx - 3, thumbCenter.dy - 4),
        kThumbRadius,
        [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(thumbCenter, kThumbRadius, sheenPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawCircle(thumbCenter, kThumbRadius, borderPaint);
  }

  @override
  bool shouldRepaint(LockoutRingPainter oldDelegate) =>
      sweepAngle != oldDelegate.sweepAngle || skyImage != oldDelegate.skyImage;
}
