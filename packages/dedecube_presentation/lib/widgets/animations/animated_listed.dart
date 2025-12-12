import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/utilities/easings.dart';
import 'package:dedecube_presentation/widgets/animations/animated_value_builder.dart';
import 'package:flutter/material.dart';

/// A widget that animates its child's size and opacity based on a [listed] state.
///
/// The animation can occur along either the vertical or horizontal axis, with
/// configurable alignment, duration, and curve settings.
///
/// If you have more than one AnimatedListed widget inside the same ListView or
/// Column that must alternate their presence, it is recommended to keep [maxSizeAt] = 1.
/// This way, the total height taken by both of them will stay the same (if
/// they're the seame height) or change smoothly to the new total height instead
/// of shifting the layout of the entire [Column] or [ListView] around.
///
/// If just one AnimatedListed is expected to appear / disappear at any given time,
/// a nice effect can be achieved by using values like [maxSizeAt] = 0.5, and
/// [transparentUntil] = 0.5, in order to first take the necessary space and then
/// fade in the object that's appearing.
///
/// Intermediate values can also lead to more creative effects, such as
/// [maxSizeAt] = 0.7 and [transparentUntil] = 0.3 which would make the object
/// start fading in while the size it's taking up is still changing, but not
/// being completely opaque until after the size animation.
class AnimatedListed extends StatelessWidget {
  /// Creates an animated listed widget.
  ///
  /// The [listed] parameter determines whether the child is shown or hidden.
  /// The [child] parameter is the widget to be animated.
  const AnimatedListed({
    required this.listed,
    required this.child,
    super.key,
    this.axis = Axis.vertical,
    this.axisAlignment = -1,
    this.curve = Easings.emphasized,
    this.duration = Durations.medium1,
    this.disableAnimation = false,
    this.transparentUntil = 0.2,
    this.maxSizeAt = 1,
  })  : assert(
          maxSizeAt >= 0 && maxSizeAt <= 1,
          'maxSizeAt must be between 0 and 1 inclusive',
        ),
        assert(
          axisAlignment >= -1 && axisAlignment <= 1,
          'axisAlignment must be between -1 and 1 inclusive',
        ),
        assert(
          transparentUntil >= 0 && transparentUntil <= 1,
          'transparentUntil must be between 0 and 1 inclusive',
        );

  /// Whether the child should be shown (true) or hidden (false).
  final bool listed;

  /// The widget to animate.
  final Widget child;

  /// The duration of the show/hide animation.
  final Duration duration;

  /// The curve to use for the show/hide animation.
  final Curve curve;

  /// The alignment of the child along the animation axis.
  ///
  /// Ranges from -1 to 1, where -1 is start/top, 0 is center, and 1 is end/bottom.
  ///
  /// With 1, the bottom (or right) of the widget will stay still while it expands
  /// With -1, the top (or left) of the widget will stay still while it expands
  /// With 0 or other values, a nice parallax effect will take place as the widget moves while its constraints expand
  final double axisAlignment;

  /// The axis along which the animation occurs.
  ///
  /// Can be either [Axis.horizontal] or [Axis.vertical].
  final Axis axis;

  /// Whether to disable the animation and show changes immediately.
  final bool disableAnimation;

  /// The progress value (0 to 1) below which the widget remains fully transparent.
  final double transparentUntil;

  /// The progress value (0 to 1) at which the widget reaches its maximum size.
  final double maxSizeAt;

  /// we apply the curve on the individual sizeFactor and opacity values so that even if they
  /// start and end at different values of the overall animation, they're curved the same way
  double _curve(double value) =>
      (listed ? curve : curve.flipped).transform(value);

  @override
  Widget build(BuildContext context) {
    return AnimatedValueBuilder(
      value: listed ? 1.0 : 0.0,
      duration: duration,
      curve: Curves.linear,
      disableAnimation: disableAnimation,
      child: child,
      builder: (context, value, child) {
        final double sizeFactor = _curve(value.rangeMap(from: (0, maxSizeAt)));

        return ClipRect(
          child: Align(
            alignment: Alignment(
              axis == Axis.horizontal ? axisAlignment : 0.0,
              axis == Axis.vertical ? axisAlignment : 0.0,
            ),
            widthFactor: axis == Axis.horizontal ? sizeFactor : 1.0,
            heightFactor: axis == Axis.vertical ? sizeFactor : 1.0,
            child: Opacity(
              opacity: _curve(value.rangeMap(from: (transparentUntil, 1))),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
