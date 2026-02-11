import 'dart:math' as math;

import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/invite_to_circle_routable.dart';
import 'package:cloudless/presentation/pages/join_circle/join_circle_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Path data for the rounded plus/cross button (viewBox 59x51, offset -4 in X).
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

class YourCircleAddMenu extends StatefulWidget {
  const YourCircleAddMenu({super.key});

  @override
  State<YourCircleAddMenu> createState() => _YourCircleAddMenuState();
}

class _YourCircleAddMenuState extends State<YourCircleAddMenu>
    with SingleTickerProviderStateMixin, MainLayout, YourCircleLayout {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnim;
  late final Animation<double> _upArrowAnim;
  late final Animation<double> _downArrowAnim;
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
    _upArrowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _downArrowAnim = Tween<double>(begin: 0, end: 1).animate(
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
    router.push(const InviteToCircleRoutable());
  }

  void _onDownTap() {
    _toggle();
    router.push(const JoinCircleRoutable());
  }

  @override
  Widget build(BuildContext context) {
    final totalUpOffset = arrowHeight + arrowSpacing;
    final totalDownOffset = addButtonSize + arrowSpacing;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: addButtonSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Up arrow (invite) - slides up from the plus button
              Positioned(
                bottom: totalDownOffset +
                    _upArrowAnim.value * totalUpOffset,
                child: Opacity(
                  opacity: _upArrowAnim.value,
                  child: GestureDetector(
                    onTap: _onUpTap,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(1.0, -1.0),
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
              // Down arrow (join) - slides down from the plus button
              Positioned(
                top: addButtonSize +
                    _downArrowAnim.value * (arrowHeight + arrowSpacing),
                child: Opacity(
                  opacity: _downArrowAnim.value,
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
              // Plus / X button
              GestureDetector(
                onTap: _toggle,
                child: Transform.rotate(
                  angle: _rotationAnim.value,
                  child: SizedBox(
                    width: addButtonSize,
                    height: addButtonSize,
                    child: AppGlassContainer(
                      config: const GlassConfig(
                        tint: MainColors.accent,
                        pathData: _kPlusPathData,
                      ),
                      child: const SizedBox.expand(),
                    ),
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
