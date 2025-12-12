import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _kHandleSize = 22.0;

class CustomTextSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color handleColor = colorScheme.tertiary;

    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: CustomPaint(
        painter: _CustomTextSelectionHandlePainter(color: handleColor),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
        ),
      ),
    );

    switch (type) {
      case TextSelectionHandleType.left:
        return Transform.rotate(angle: math.pi / 2.0, child: handle);
      case TextSelectionHandleType.right:
        return handle;
      case TextSelectionHandleType.collapsed:
        return Transform.rotate(angle: math.pi / 4.0, child: handle);
    }
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, 0);
      case TextSelectionHandleType.right:
        return Offset.zero;
      case TextSelectionHandleType.collapsed:
        return const Offset(_kHandleSize / 2, -4);
    }
  }
}

// ignore: one_class_per_file
class _CustomTextSelectionHandlePainter extends CustomPainter {
  _CustomTextSelectionHandlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CustomTextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}
