import 'dart:ui' as ui;

import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';

/// CustomPainter that draws a line graph for daily lockout minutes.
class LockoutLineChartPainter extends CustomPainter {
  LockoutLineChartPainter({
    required this.dailyMinutes,
    this.highlightIndex = -1,
  });

  final List<int> dailyMinutes;
  final int highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyMinutes.length != 7) return;

    final maxMinutes = dailyMinutes.reduce((a, b) => a > b ? a : b);
    // Vertical padding so dots aren't clipped at edges
    const vPad = 8.0;
    final chartH = size.height - vPad * 2;

    // Subtle grid lines at 25%, 50%, 75%
    final gridPaint = Paint()
      ..color = MainColors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (final frac in [0.25, 0.5, 0.75]) {
      final y = vPad + chartH * (1 - frac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Compute point positions
    final stepX = size.width / 6; // 7 points, 6 gaps
    final points = <Offset>[];
    for (var i = 0; i < 7; i++) {
      final x = i * stepX;
      final fraction = maxMinutes > 0 ? dailyMinutes[i] / maxMinutes : 0.0;
      final y = vPad + chartH * (1 - fraction);
      points.add(Offset(x, y));
    }

    // Gradient fill under the line
    if (maxMinutes > 0) {
      final fillPath = Path()..moveTo(points.first.dx, size.height);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, vPad),
          Offset(0, size.height),
          [
            MainColors.accent.withOpacity(0.25),
            MainColors.accent.withOpacity(0.0),
          ],
        );
      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    if (maxMinutes > 0) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      final linePaint = Paint()
        ..color = MainColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Dots at each data point
    for (var i = 0; i < points.length; i++) {
      final isHighlighted = i == highlightIndex;
      final dotRadius = isHighlighted ? 5.0 : 3.0;
      final dotPaint = Paint()
        ..color = isHighlighted ? MainColors.accent : MainColors.accent.withOpacity(0.8);
      canvas.drawCircle(points[i], dotRadius, dotPaint);

      // White inner dot on highlight
      if (isHighlighted) {
        canvas.drawCircle(
          points[i],
          2.0,
          Paint()..color = MainColors.dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LockoutLineChartPainter old) =>
      old.dailyMinutes != dailyMinutes ||
      old.highlightIndex != highlightIndex;
}
