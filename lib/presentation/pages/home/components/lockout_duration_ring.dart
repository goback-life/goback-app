import 'dart:ui' as ui;

import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_ring_painter.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LockoutDurationRing extends HookWidget {
  const LockoutDurationRing({
    super.key,
    required this.duration,
    required this.onDurationChanged,
    this.minMinutes = 30,
    this.size = 220.0,
  });

  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;
  final int minMinutes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final skyImage = useState<ui.Image?>(null);
    final isDragging = useState(false);

    // Load the sky image once
    useEffect(() {
      _loadSkyImage().then((img) => skyImage.value = img);
      return null;
    }, const []);

    final sweepAngle = durationToSweepAngle(duration);
    final center = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Glass disc interior (behind the ring)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(kThumbRadius),
              child: ClipOval(
                child: AppGlassContainer(
                  config: const GlassConfig(cornerRadius: 999),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          // Ring + gesture layer
          GestureDetector(
            onPanStart: (details) {
              isDragging.value = true;
              _handleDrag(details.localPosition, center);
            },
            onPanUpdate: (details) {
              _handleDrag(details.localPosition, center);
            },
            onPanEnd: (_) => isDragging.value = false,
            child: CustomPaint(
              size: Size(size, size),
              painter: LockoutRingPainter(
                sweepAngle: sweepAngle,
                skyImage: skyImage.value,
                trackColor: Colors.white.withValues(alpha: 0.05),
                glowColor: const Color(0xFF5BA3D9).withValues(alpha: 0.1),
                tickColor: Colors.white.withValues(alpha: 0.18),
                thumbColor: const Color(0xFF5BA3D9),
              ),
            ),
          ),
          // Center duration text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  duration.inHours >= 1 ? 'hours' : 'minutes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrag(Offset localPosition, double center) {
    final angle = polarAngleFromPoint(
      localPosition.dx,
      localPosition.dy,
      center,
      center,
    );
    final rawDuration = angleToDuration(angle);
    final snapped = snapDuration(rawDuration, minMinutes: minMinutes);

    if (snapped != duration) {
      HapticFeedback.selectionClick();
      onDurationChanged(snapped);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return minutes == 0
          ? '$hours:00'
          : '$hours:${minutes.toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}';
  }

  Future<ui.Image> _loadSkyImage() async {
    final data = await rootBundle.load(Assets.png.backgroundGoback.path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
