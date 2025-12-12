import 'package:dedecube_presentation/utilities/easings.dart';
import 'package:flutter/material.dart';

/// A widget that smoothly animates changes of a [Color] value using implicit animations.
///
/// This widget uses [ImplicitlyAnimatedWidget] to automatically animate the color
/// transition when the [color] property changes.
class AnimatedColorBuilder extends ImplicitlyAnimatedWidget {
  /// Creates an animated builder that transitions its color value over time.
  ///
  /// * [color] is the target color to animate to.
  /// * [builder] is called each frame with the current animated color value.
  /// * [curve] defines the timing curve of the animation (defaults to [Easings.emphasized]).
  /// * [duration] is the length of the animation (defaults to [Durations.medium1]).
  /// * [disableAnimation] when true, the color changes immediately without animation.
  /// * [child] is an optional child widget that will be passed to the [builder].
  const AnimatedColorBuilder({
    required this.color,
    required this.builder,
    super.key,
    super.curve = Easings.emphasized,
    super.duration = Durations.medium1,
    this.disableAnimation = false,
    this.child,
  });

  final Color color;
  final Widget? child;
  final Widget Function(BuildContext context, Color value, Widget? child)
      builder;
  final bool disableAnimation;

  @override
  AnimatedWidgetBaseState<AnimatedColorBuilder> createState() =>
      _AnimatedColorBuilderState();
}

/// The state class for [AnimatedColorBuilder].
///
/// Handles the animation of color transitions using [ColorTween].
class _AnimatedColorBuilderState
    extends AnimatedWidgetBaseState<AnimatedColorBuilder> {
  ColorTween? _color;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color = (visitor(
      _color,
      widget.color,
      (dynamic value) => ColorTween(begin: value),
    )! as ColorTween);
    if (widget.disableAnimation) {
      _color = ColorTween(
        begin: widget.color,
        end: widget.color,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final val = _color!.evaluate(animation);
    return widget.builder(context, val ?? widget.color, widget.child);
  }
}
