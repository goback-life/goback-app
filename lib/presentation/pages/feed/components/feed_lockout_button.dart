import 'dart:ui' as ui;

import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/time_limit/domain/providers/time_limit_tracker_notifier_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/components/manual_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Triangle path data for the lockout button (viewBox 86x102).
const _kTrianglePathData = GlassPathData(
  commands: [
    ['M', 10.0244, 55.1414],
    ['C', 1.42744, 48.7205, 2.1564, 35.6124, 11.4122, 30.1843],
    ['L', 59.3289, 2.0836],
    ['C', 69.3286, -3.7807, 81.917, 3.43033, 81.917, 15.0227],
    ['L', 81.917, 78.9116],
    ['C', 81.917, 91.2584, 67.8333, 98.3179, 57.941, 90.9295],
    ['L', 10.0244, 55.1414],
    ['Z'],
  ],
  viewBoxWidth: 86,
  viewBoxHeight: 102,
);

/// Lockout button with liquid glass effect.
///
/// When [isRefreshing] is true, the glass caustic brightens with a
/// light-surge animation and a haptic fires.
class FeedLockoutButton extends HookConsumerWidget {
  const FeedLockoutButton({super.key, this.isRefreshing = false});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;

    final timeLimitAsync = ref.watch(timeLimitTrackerNotifierProvider);
    final isDailyLimitReached = timeLimitAsync.whenOrNull(
          data: (tl) => tl.isLimitReached,
        ) ??
        false;

    if (isDailyLimitReached) return const SizedBox.shrink();

    // Match SVG viewBox proportions (86x102)
    final btnWidth = 86 * s;
    final btnHeight = 102 * s;

    // -- Refresh glow animation: surge up (300ms) then ease back (800ms) --
    final glowController = useAnimationController(
      duration: const Duration(milliseconds: 1100),
    );
    final glowValue = useAnimation(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 300,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 800,
        ),
      ]).animate(glowController),
    );

    // Trigger glow + haptic when refresh starts
    final prevRefreshing = useRef(false);
    useEffect(() {
      if (isRefreshing && !prevRefreshing.value) {
        HapticFeedback.mediumImpact();
        glowController.forward(from: 0);
      }
      prevRefreshing.value = isRefreshing;
      return null;
    }, [isRefreshing]);

    return GestureDetector(
      onTap: () => _onTap(context, ref),
      child: SizedBox(
        width: btnWidth,
        height: btnHeight,
        child: Stack(
          children: [
            if (!kNativeGlassAvailable) ...[
              // Layer 1: Drop shadow
              CustomPaint(
                size: Size(btnWidth, btnHeight),
                painter: _ShadowPainter(),
              ),
              // Layer 2: Uniform subtle backdrop blur
              ClipPath(
                clipper: _TriangleClipper(),
                child: BackdropFilter(
                  filter: ui.ImageFilter.compose(
                    outer: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    inner: ui.ImageFilter.matrix(
                      (Matrix4.identity()
                            ..translate(btnWidth / 2, btnHeight / 2)
                            ..scale(1.0026)
                            ..translate(-btnWidth / 2, -btnHeight / 2))
                          .storage,
                    ),
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
            if (kNativeGlassAvailable)
              Positioned.fill(
                child: ClipPath(
                  clipper: _TriangleClipper(),
                  child: UiKitView(
                    viewType: 'app_liquid_glass',
                    creationParams: GlassConfig(
                      tint: MainColors.accent,
                      pathData: _kTrianglePathData,
                    ).toCreationParams(),
                    creationParamsCodec: const StandardMessageCodec(),
                  ),
                ),
              ),
            // Overlay: full effects (fallback) or highlights-only (native)
            CustomPaint(
              size: Size(btnWidth, btnHeight),
              painter: _GlassOverlayPainter(
                glowIntensity: glowValue,
                nativeMode: kNativeGlassAvailable,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    ref.read(friendsLockedOutCacheProvider.notifier).ensureFresh();

    final duration = await ManualLockoutDialog.show(context);
    if (duration == null || !context.mounted) return;

    try {
      final notifier = ref.read(manualLockoutNotifierProvider.notifier);
      await notifier.setLockout(duration);
      ref.invalidate(timeLimitTrackerNotifierProvider);
      if (context.mounted) {
        router.go(const ManualLockoutRoutable());
      }
    } catch (e, st) {
      logger.error(
        'Error setting manual lockout',
        exception: e,
        stackTrace: st,
      );
    }
  }
}

// -- SVG path: left-pointing rounded triangle (viewBox 0 0 86 102) --

Path _trianglePath(Size size) {
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

/// Clips to the triangle shape for [BackdropFilter].
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _trianglePath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Soft drop shadow behind the triangle.
class _ShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _trianglePath(size);
    final paint = Paint()
      ..color = const Color(0xFF191919).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Glass overlay: accent tint, subtle inner shadow, and edge highlights.
///
/// When [nativeMode] is true, only effects 5a/5b (animated highlights +
/// caustic) are painted — the native glass handles tint, blur, and shadow.
class _GlassOverlayPainter extends CustomPainter {
  _GlassOverlayPainter({this.glowIntensity = 0.0, this.nativeMode = false});

  /// 0.0 = normal, 1.0 = peak glow (during refresh).
  final double glowIntensity;

  /// When true, skip effects 1-4 (native glass handles them).
  final bool nativeMode;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _trianglePath(size);
    final bounds = path.getBounds();

    if (!nativeMode) {
      // 1. Accent tint
      canvas.drawPath(
        path,
        Paint()..color = MainColors.accent.withValues(alpha: 0.20),
      );

      // -- Clipped interior effects --
      canvas.save();
      canvas.clipPath(path);

      // 2. Body gradient: lighter NW -> darker SE
      canvas.drawPaint(
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(bounds.left, bounds.top),
            Offset(bounds.right, bounds.bottom),
            [
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.08),
            ],
            [0.0, 0.35, 1.0],
          ),
      );

      // 3. Inner shadow — subtle darkening on the lower edge near the tip
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..shader = ui.Gradient.radial(
            Offset(bounds.left + bounds.width * 0.18, bounds.center.dy * 1.1),
            bounds.width * 0.40,
            [
              Colors.black.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
      );

      // 4. Painted edge refraction glow
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..shader = ui.Gradient.linear(
            Offset(bounds.center.dx, bounds.top),
            Offset(bounds.center.dx, bounds.center.dy),
            [
              Colors.white.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
      );

      canvas.restore();
    }

    // 5a. Direct reflection — NW light (315 deg) hitting the glass surface.
    //     Glow boost: peak alpha rises from 0.80 -> 1.0 during refresh.
    final reflAlpha = 0.80 + 0.20 * glowIntensity;
    final reflMid = 0.20 + 0.30 * glowIntensity;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 0.5 * glowIntensity
        ..shader = ui.Gradient.linear(
          Offset(bounds.left, bounds.top),
          Offset(bounds.right, bounds.bottom),
          [
            Colors.white.withValues(alpha: reflAlpha),
            Colors.white.withValues(alpha: reflMid),
            Colors.transparent,
          ],
          [0.0, 0.45, 0.75],
        ),
    );

    // 5b. Caustic — NW light refracts through the glass body.
    //     Glow boost: alpha rises from 0.28 -> 0.70, radius widens.
    final causticAlpha = 0.28 + 0.42 * glowIntensity;
    final causticRadius = bounds.width * (0.30 + 0.15 * glowIntensity);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 0.5 * glowIntensity
        ..shader = ui.Gradient.radial(
          Offset(bounds.right * 0.82, bounds.bottom * 0.88),
          causticRadius,
          [
            Colors.white.withValues(alpha: causticAlpha),
            Colors.transparent,
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassOverlayPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity ||
      oldDelegate.nativeMode != nativeMode;
}
