import 'dart:io';

import 'dart:ui' as ui;

import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether the device supports native Apple Liquid Glass (iOS 26+).
final bool kNativeGlassAvailable = _checkNativeGlass();

bool _checkNativeGlass() {
  if (!Platform.isIOS) return false;
  try {
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'(\d+)\.').firstMatch(version);
    if (match == null) return false;
    return int.parse(match.group(1)!) >= 26;
  } catch (_) {
    return false;
  }
}

/// Wraps a subtree that contains [AppGlassContainer] widgets.
///
/// On iOS 26+: passthrough (native compositing is automatic).
/// On Android / iOS < 26: passthrough (BackdropFilter handles glass inline).
class AppGlassLayer extends StatelessWidget {
  const AppGlassLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// A platform-adaptive liquid glass surface.
///
/// - iOS 26+: native SwiftUI `.glassEffect()` via platform view.
/// - Android / iOS < 26: shader-based glass via [LiquidGlass].
///
/// Must be a descendant of [AppGlassLayer] on non-native platforms.
class AppGlassContainer extends StatelessWidget {
  const AppGlassContainer({
    super.key,
    required this.child,
    this.config = const GlassConfig(),
  });

  final Widget child;
  final GlassConfig config;

  @override
  Widget build(BuildContext context) {
    if (kNativeGlassAvailable) {
      return _NativeGlass(config: config, child: child);
    }
    return _ShaderGlass(config: config, child: child);
  }
}

/// iOS 26+ implementation using native SwiftUI platform view.
class _NativeGlass extends StatelessWidget {
  const _NativeGlass({required this.config, required this.child});

  final GlassConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: UiKitView(
              viewType: 'app_liquid_glass',
              creationParams: config.toCreationParams(),
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
        ),
        child,
      ],
    );
    if (config.pathData != null) {
      return ClipPath(
        clipper: _GlassPathClipper(config.pathData!),
        child: stack,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(config.cornerRadius),
      child: stack,
    );
  }
}

/// Clips to a custom path defined by [GlassPathData].
class _GlassPathClipper extends CustomClipper<Path> {
  _GlassPathClipper(this.pathData);

  final GlassPathData pathData;

  @override
  Path getClip(Size size) {
    final sx = size.width / pathData.viewBoxWidth;
    final sy = size.height / pathData.viewBoxHeight;
    final path = Path();
    for (final cmd in pathData.commands) {
      if (cmd.isEmpty) continue;
      final op = cmd[0] as String;
      switch (op) {
        case 'M':
          path.moveTo(
            (cmd[1] as num).toDouble() * sx,
            (cmd[2] as num).toDouble() * sy,
          );
        case 'L':
          path.lineTo(
            (cmd[1] as num).toDouble() * sx,
            (cmd[2] as num).toDouble() * sy,
          );
        case 'C':
          path.cubicTo(
            (cmd[1] as num).toDouble() * sx,
            (cmd[2] as num).toDouble() * sy,
            (cmd[3] as num).toDouble() * sx,
            (cmd[4] as num).toDouble() * sy,
            (cmd[5] as num).toDouble() * sx,
            (cmd[6] as num).toDouble() * sy,
          );
        case 'Z':
          path.close();
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _GlassPathClipper oldClipper) =>
      !identical(oldClipper.pathData, pathData);
}

/// Android / iOS < 26 fallback: magnification + glass overlay.
class _ShaderGlass extends StatelessWidget {
  const _ShaderGlass({required this.config, required this.child});

  final GlassConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = config.cornerRadius;
    final sigma = config.variant == GlassVariant.regular ? 15.0 : 1.0;
    final hasCustomPath = config.pathData != null;

    final backdrop = BackdropFilter(
      filter: ui.ImageFilter.compose(
        outer: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        inner: ui.ImageFilter.matrix(
          (Matrix4.identity()..scale(1.0026)).storage,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoundedGlassOverlay(
                cornerRadius: radius,
                tint: config.tint,
              ),
            ),
          ),
          child,
        ],
      ),
    );

    final clipped = hasCustomPath
        ? ClipPath(
            clipper: _GlassPathClipper(config.pathData!),
            child: backdrop,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: backdrop,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: hasCustomPath ? null : BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18191919),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: clipped,
    );
  }
}

/// Glass overlay for rounded rectangles: tint, gradient, inner shadow,
/// and NW directional edge highlights.
class _RoundedGlassOverlay extends CustomPainter {
  _RoundedGlassOverlay({required this.cornerRadius, this.tint});

  final double cornerRadius;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cornerRadius),
    );
    final bounds = Offset.zero & size;

    // 0. Tint fill — light wash of the tint color
    if (tint != null) {
      canvas.drawRRect(rrect, Paint()..color = tint!.withValues(alpha: 0.15));
    }

    // 1. Subtle surface tint for presence on light backgrounds
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF5A8FB2).withValues(alpha: 0.03),
    );

    // -- Clipped interior --
    canvas.save();
    canvas.clipRRect(rrect);

    // 2. Body gradient: very subtle depth
    canvas.drawPaint(
      Paint()
        ..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [
          Colors.black.withValues(alpha: 0.01),
          Colors.black.withValues(alpha: 0.025),
        ]),
    );

    // 3. Inner shadow — barely there
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.03),
        ]),
    );

    canvas.restore();

    // 4. Edge highlight — subtle border definition
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [
            Colors.white.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.04),
            Colors.black.withValues(alpha: 0.02),
          ],
          [0.0, 0.45, 0.75],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _RoundedGlassOverlay old) =>
      old.cornerRadius != cornerRadius || old.tint != tint;
}
