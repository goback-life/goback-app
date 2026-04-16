import 'dart:math';

import 'package:flutter/material.dart';

/// Data for a single activity bubble.
class ActivityBubble {
  const ActivityBubble({
    required this.label,
    required this.emoji,
    required this.totalMinutes,
  });

  final String label;
  final String emoji;
  final int totalMinutes;
}

/// Positioned bubble after layout packing.
class _PackedBubble {
  _PackedBubble({
    required this.bubble,
    required this.radius,
    required this.center,
    required this.color,
  });

  final ActivityBubble bubble;
  final double radius;
  Offset center;
  final Color color;
}

/// 8 muted palette colors for dark backgrounds.
const _kPalette = [
  Color(0xFF598EB5),
  Color(0xFF6B8E6B),
  Color(0xFFB57859),
  Color(0xFF8B7BB5),
  Color(0xFFB5A259),
  Color(0xFF59B5A3),
  Color(0xFFB55976),
  Color(0xFF7BAAB5),
];

/// CustomPainter that draws a packed bubble cloud of lockout activities.
class ActivityBubbleCloudPainter extends CustomPainter {
  ActivityBubbleCloudPainter({required this.bubbles});

  final List<ActivityBubble> bubbles;

  @override
  void paint(Canvas canvas, Size size) {
    if (bubbles.isEmpty) return;

    final packed = _packBubbles(size);
    if (packed.isEmpty) return;

    for (final b in packed) {
      // Filled circle
      final circlePaint = Paint()..color = b.color.withValues(alpha: 0.70);
      canvas.drawCircle(b.center, b.radius, circlePaint);

      // Emoji
      final emojiSpan = TextSpan(
        text: b.bubble.emoji,
        style: TextStyle(fontSize: b.radius * 0.6),
      );
      final emojiPainter = TextPainter(
        text: emojiSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final showLabel = b.radius >= 24;
      final emojiY = showLabel
          ? b.center.dy - emojiPainter.height * 0.7
          : b.center.dy - emojiPainter.height / 2;
      emojiPainter.paint(
        canvas,
        Offset(b.center.dx - emojiPainter.width / 2, emojiY),
      );

      // Duration label (only for larger bubbles)
      if (showLabel) {
        final label = _formatMinutes(b.bubble.totalMinutes);
        final labelSpan = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: (b.radius * 0.28).clamp(8.0, 13.0),
            fontWeight: FontWeight.w500,
            fontFamily: 'Quicksand',
            color: Colors.white.withValues(alpha: 0.9),
          ),
        );
        final labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(
          canvas,
          Offset(
            b.center.dx - labelPainter.width / 2,
            b.center.dy + emojiPainter.height * 0.1,
          ),
        );
      }
    }
  }

  /// Packs bubbles using a spiral placement algorithm.
  List<_PackedBubble> _packBubbles(Size size) {
    final minDim = min(size.width, size.height);
    final maxRadius = minDim * 0.25;
    const minRadius = 20.0;

    // Compute raw radii from sqrt(totalMinutes)
    final maxMinutes = bubbles.fold<int>(
      0,
      (prev, b) => b.totalMinutes > prev ? b.totalMinutes : prev,
    );
    if (maxMinutes == 0) return [];

    final sqrtMax = sqrt(maxMinutes.toDouble());
    final packed = <_PackedBubble>[];

    for (var i = 0; i < bubbles.length; i++) {
      final sqrtVal = sqrt(bubbles[i].totalMinutes.toDouble());
      final radius = max(minRadius, (sqrtVal / sqrtMax) * maxRadius);
      packed.add(
        _PackedBubble(
          bubble: bubbles[i],
          radius: radius,
          center: Offset.zero,
          color: _kPalette[i % _kPalette.length],
        ),
      );
    }

    // Sort largest first
    packed.sort((a, b) => b.radius.compareTo(a.radius));

    // Place first bubble at center
    final cx = size.width / 2;
    final cy = size.height / 2;
    packed[0].center = Offset(cx, cy);

    // Place remaining via spiral scan
    for (var i = 1; i < packed.length; i++) {
      packed[i].center = _findPosition(packed, i, cx, cy);
    }

    // Centering pass: translate all so bounding box is centered
    _centerBubbles(packed, size);

    return packed;
  }

  /// Spirals outward to find a non-overlapping position.
  Offset _findPosition(
    List<_PackedBubble> packed,
    int index,
    double cx,
    double cy,
  ) {
    const angleStep = 0.3;
    const distStep = 4.0;
    var angle = 0.0;
    var distance = packed[0].radius + packed[index].radius + 2;

    for (var attempt = 0; attempt < 2000; attempt++) {
      final x = cx + distance * cos(angle);
      final y = cy + distance * sin(angle);
      final candidate = Offset(x, y);

      var overlaps = false;
      for (var j = 0; j < index; j++) {
        final dist = (candidate - packed[j].center).distance;
        if (dist < packed[j].radius + packed[index].radius + 2) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) return candidate;

      angle += angleStep;
      if (angle > 2 * pi) {
        angle -= 2 * pi;
        distance += distStep;
      }
    }

    return Offset(cx, cy); // fallback
  }

  /// Translates all bubbles so their bounding box is centered in the canvas.
  void _centerBubbles(List<_PackedBubble> packed, Size size) {
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;

    for (final b in packed) {
      minX = min(minX, b.center.dx - b.radius);
      maxX = max(maxX, b.center.dx + b.radius);
      minY = min(minY, b.center.dy - b.radius);
      maxY = max(maxY, b.center.dy + b.radius);
    }

    final bboxCx = (minX + maxX) / 2;
    final bboxCy = (minY + maxY) / 2;
    final dx = size.width / 2 - bboxCx;
    final dy = size.height / 2 - bboxCy;

    for (final b in packed) {
      b.center = b.center.translate(dx, dy);
    }
  }

  static String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  bool shouldRepaint(covariant ActivityBubbleCloudPainter old) =>
      old.bubbles != bubbles;
}
