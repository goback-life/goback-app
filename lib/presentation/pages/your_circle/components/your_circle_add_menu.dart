import 'dart:math' as math;

import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/join_circle/join_circle_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/components/invite_card_popup.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Path data for the rounded plus/cross button (viewBox 51x51).
const _kPlusPathData = GlassPathData(
  viewBoxWidth: 51,
  viewBoxHeight: 51,
  commands: [
    ['M', 25.5, 0],
    ['C', 29.9947, 0, 33.6387, 3.64401, 33.6387, 8.13867],
    ['L', 33.6387, 17.3613],
    ['L', 42.8613, 17.3613],
    ['C', 47.356, 17.3613, 51.0, 21.0053, 51.0, 25.5],
    ['C', 51.0, 29.9947, 47.356, 33.6387, 42.8613, 33.6387],
    ['L', 33.6387, 33.6387],
    ['L', 33.6387, 42.8613],
    ['C', 33.6387, 47.356, 29.9947, 51.0, 25.5, 51.0],
    ['C', 21.0053, 51.0, 17.3613, 47.356, 17.3613, 42.8613],
    ['L', 17.3613, 33.6387],
    ['L', 8.1387, 33.6387],
    ['C', 3.64401, 33.6387, 0, 29.9947, 0, 25.5],
    ['C', 0, 21.0053, 3.64401, 17.3613, 8.1387, 17.3613],
    ['L', 17.3613, 17.3613],
    ['L', 17.3613, 8.13867],
    ['C', 17.3613, 3.64401, 21.0053, 0, 25.5, 0],
    ['Z'],
  ],
);

/// Path data for the down-pointing arrow (viewBox 48x57.4862).
const _kArrowDownPathData = GlassPathData(
  viewBoxWidth: 48.0027,
  viewBoxHeight: 57.4862,
  commands: [
    ['M', 23.9598, 0],
    ['C', 27.1676, 0, 29.7683, 2.60079, 29.7684, 5.80859],
    ['L', 29.7684, 37.7227],
    ['L', 37.9158, 29.5752],
    ['C', 40.2233, 27.2678, 43.9648, 27.2678, 46.2723, 29.5752],
    ['C', 48.5796, 31.8826, 48.5796, 35.6233, 46.2723, 37.9307],
    ['L', 28.4451, 55.7568],
    ['C', 26.5491, 57.6525, 23.6863, 57.9892, 21.4451, 56.7695],
    ['C', 20.7592, 56.4814, 20.116, 56.0595, 19.5574, 55.501],
    ['L', 1.73029, 37.6748],
    ['C', -0.576758, 35.3675, -0.576771, 31.6267, 1.73029, 29.3193],
    ['C', 4.03779, 27.0119, 7.77923, 27.012, 10.0867, 29.3193],
    ['L', 18.1512, 37.3818],
    ['L', 18.1512, 5.80859],
    ['C', 18.1512, 2.6008, 20.752, 0.0000237074, 23.9598, 0],
    ['Z'],
  ],
);

/// Rotates all points in [data] by [angle] radians around the viewBox centre.
///
/// This ensures the glass overlay's NW lighting interacts differently with the
/// shape at each rotation angle (the gradient stays screen-fixed while the path
/// rotates within it).
GlassPathData _rotatePath(GlassPathData data, double angle) {
  if (angle == 0) return data;
  final cx = data.viewBoxWidth / 2;
  final cy = data.viewBoxHeight / 2;
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);

  double rx(double x, double y) => cx + (x - cx) * cosA - (y - cy) * sinA;
  double ry(double x, double y) => cy + (x - cx) * sinA + (y - cy) * cosA;

  final rotated = <List<dynamic>>[];
  for (final cmd in data.commands) {
    switch (cmd[0] as String) {
      case 'M':
        final x = (cmd[1] as num).toDouble();
        final y = (cmd[2] as num).toDouble();
        rotated.add(['M', rx(x, y), ry(x, y)]);
      case 'L':
        final x = (cmd[1] as num).toDouble();
        final y = (cmd[2] as num).toDouble();
        rotated.add(['L', rx(x, y), ry(x, y)]);
      case 'C':
        final x1 = (cmd[1] as num).toDouble();
        final y1 = (cmd[2] as num).toDouble();
        final x2 = (cmd[3] as num).toDouble();
        final y2 = (cmd[4] as num).toDouble();
        final x3 = (cmd[5] as num).toDouble();
        final y3 = (cmd[6] as num).toDouble();
        rotated.add([
          'C',
          rx(x1, y1), ry(x1, y1),
          rx(x2, y2), ry(x2, y2),
          rx(x3, y3), ry(x3, y3),
        ]);
      case 'Z':
        rotated.add(['Z']);
    }
  }
  return GlassPathData(
    commands: rotated,
    viewBoxWidth: data.viewBoxWidth,
    viewBoxHeight: data.viewBoxHeight,
  );
}

class YourCircleAddMenu extends StatefulWidget {
  const YourCircleAddMenu({super.key});

  @override
  State<YourCircleAddMenu> createState() => _YourCircleAddMenuState();
}

class _YourCircleAddMenuState extends State<YourCircleAddMenu>
    with SingleTickerProviderStateMixin, MainLayout, YourCircleLayout {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnim;
  late final Animation<double> _firstArrowAnim;
  late final Animation<double> _secondArrowAnim;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnim = Tween<double>(begin: 0, end: math.pi / 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Both arrows slide ABOVE the plus. First arrow (up/invite) is furthest.
    _firstArrowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _secondArrowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onUpTap() {
    _toggle();
    showInviteCardPopup(context);
  }

  void _onDownTap() {
    _toggle();
    router.push(const JoinCircleRoutable());
  }

  @override
  Widget build(BuildContext context) {
    // Offsets: both arrows stack above the plus button.
    // Slot 1 (closest to plus) = down arrow (join).
    // Slot 2 (furthest from plus) = up arrow (invite).
    final slot1Offset = addButtonSize + arrowSpacing;
    final slot2Offset = slot1Offset + arrowHeight + arrowSpacing;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final rotatedPlusPath = _rotatePath(
          _kPlusPathData,
          _rotationAnim.value,
        );

        // Full height so arrows stay within Stack bounds for hit testing.
        final fullHeight = slot2Offset + arrowHeight;

        return SizedBox(
          width: addButtonSize,
          height: fullHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Up arrow (invite) — furthest above the plus
              Positioned(
                left: (addButtonSize - arrowWidth) / 2,
                bottom: _firstArrowAnim.value * slot2Offset,
                child: IgnorePointer(
                  ignoring: !_expanded,
                  child: Opacity(
                    opacity: _firstArrowAnim.value,
                    child: GestureDetector(
                      onTap: _onUpTap,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(1.0, -1.0, 1.0),
                        child: SizedBox(
                          width: arrowWidth,
                          height: arrowHeight,
                          child: AppGlassContainer(
                            config: const GlassConfig(
                              tint: MainColors.accent,
                              pathData: _kArrowDownPathData,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Down arrow (join) — directly above the plus
              Positioned(
                left: (addButtonSize - arrowWidth) / 2,
                bottom: _secondArrowAnim.value * slot1Offset,
                child: IgnorePointer(
                  ignoring: !_expanded,
                  child: Opacity(
                    opacity: _secondArrowAnim.value,
                    child: GestureDetector(
                      onTap: _onDownTap,
                      child: SizedBox(
                        width: arrowWidth,
                        height: arrowHeight,
                        child: AppGlassContainer(
                          config: const GlassConfig(
                            tint: MainColors.accent,
                            pathData: _kArrowDownPathData,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Plus / X button — path rotates so glass lighting shifts
              GestureDetector(
                onTap: _toggle,
                child: SizedBox(
                  width: addButtonSize,
                  height: addButtonSize,
                  child: AppGlassContainer(
                    config: GlassConfig(
                      tint: MainColors.accent,
                      pathData: rotatedPlusPath,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
