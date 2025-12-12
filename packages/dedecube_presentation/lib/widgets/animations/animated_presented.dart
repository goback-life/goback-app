import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/utilities/easings.dart';
import 'package:dedecube_presentation/widgets/animations/animated_value_builder.dart';
import 'package:flutter/material.dart';

/// Defines the animation style for the [AnimatedPresented] widget.
enum PresentMode {
  /// Scales the child widget from [AnimatedPresented.offScale] to 1.0
  scale,

  /// Slides the child widget from [AnimatedPresented.slideOffset] to (0,0)
  slide,
}

/// A widget that animates its child's presentation state using scale, slide, and fade effects.
///
/// The widget can animate its child in two ways:
/// * Scale mode: The child scales up/down while fading
/// * Slide mode: The child slides from/to an offset while fading
///
/// Example:
/// ```dart
/// AnimatedPresented(
///   presented: _isVisible,
///   child: Text('Hello'),
///   presentMode: PresentMode.scale,
///   duration: Duration(milliseconds: 300),
/// )
/// ```
class AnimatedPresented extends StatelessWidget {
  const AnimatedPresented({
    required this.presented,
    required this.child,
    super.key,
    this.offScale = 0.8,
    this.curve = Easings.emphasized,
    this.duration = Durations.long1,
    this.presentMode = PresentMode.scale,
    this.slideOffset = const Offset(0, 200),
    this.fadeFirstFraction = 0.0,
  })  : assert(
          offScale > 0 && offScale <= 1,
          'offScale must be greater than zero and less than or equal to 1',
        ),
        assert(
          fadeFirstFraction >= 0 && fadeFirstFraction <= 1,
          'fadeFirstFraction must be between 0 and 1 inclusive',
        );

  /// Whether the child should be presented (visible and interactive)
  final bool presented;

  /// The widget to animate
  final Widget child;

  /// The easing curve to use for the animation
  final Curve curve;

  /// The duration of the presentation animation
  final Duration duration;

  /// The initial scale factor when not presented in [PresentMode.scale]
  final double offScale;

  /// The presentation animation mode
  final PresentMode presentMode;

  /// The initial offset when not presented in [PresentMode.slide]
  final Offset slideOffset;

  /// Controls the fade timing during the animation:
  /// * 1.0: the child completely fades out at 50% of the animation
  /// * 0.0: the child fades out during the whole animation
  ///
  /// This is useful when coordinating multiple [AnimatedPresented] widgets
  /// to create smooth transitions between different UI states.
  final double fadeFirstFraction;

  @override
  Widget build(BuildContext context) {
    final opacityFrom = fadeFirstFraction.rangeMap(to: (0.0, 0.5));
    return IgnorePointer(
      ignoring: !presented,
      child: AnimatedValueBuilder(
        value: presented ? 1 : 0,
        duration: duration,
        curve: curve,
        child: child,
        builder: (context, value, child) {
          final faded = Opacity(
            opacity: value.rangeMap(from: (opacityFrom, 1.0)),
            child: child,
          );
          return switch (presentMode) {
            PresentMode.scale => Transform.scale(
                scale: value.rangeMap(to: (offScale, 1.0)),
                alignment: Alignment.center,
                child: faded,
              ),
            PresentMode.slide => Transform.translate(
                offset: Offset(
                  value.rangeMap(to: (slideOffset.dx, 0.0)),
                  value.rangeMap(to: (slideOffset.dy, 0.0)),
                ),
                child: faded,
              ),
          };
        },
      ),
    );
  }
}
