import 'package:dedecube_presentation/utilities/easings.dart';
import 'package:flutter/material.dart';

/// A widget that implicitly animates changes to a numeric value and rebuilds
/// its child using a builder pattern.
///
/// This widget automatically animates transitions when its [value] parameter
/// changes, using the specified [curve] and [duration].
///
/// Example usage:
/// ```dart
/// AnimatedValueBuilder(
///   value: 1.0,
///   builder: (context, value, child) => Opacity(
///     opacity: value,
///     child: child,
///   ),
///   child: const Text('Hello'),
/// )
/// ```
class AnimatedValueBuilder extends ImplicitlyAnimatedWidget {
  /// Creates an [AnimatedValueBuilder].
  ///
  /// The [value] parameter specifies the value to be animated.
  /// The [builder] parameter is called every time the animation value changes.
  ///
  /// The [curve], [duration], and [disableAnimation] parameters control the
  /// animation behavior.
  const AnimatedValueBuilder({
    required this.value,
    required this.builder,
    super.key,

    /// The curve to apply when animating the value.
    /// Defaults to [Easings.emphasized] for a smooth, emphasized animation.
    super.curve = Easings.emphasized,

    /// The duration over which to animate the value.
    /// Defaults to [Durations.medium1] for a moderate animation speed.
    super.duration = Durations.medium1,
    this.disableAnimation = false,
    this.child,
  });

  /// The value to animate to.
  final double value;

  /// Optional child widget that will be passed to the [builder].
  ///
  /// This is useful when part of the widget subtree does not depend on the
  /// animation value and can be cached.
  final Widget? child;

  /// Function that builds the widget tree based on the current animation value.
  ///
  /// Called every time the animation value changes with the current [BuildContext],
  /// the interpolated [value], and the optional [child].
  final Widget Function(BuildContext context, double value, Widget? child)
      builder;

  /// When true, animations are disabled and the widget immediately jumps to the target value.
  final bool disableAnimation;

  @override
  AnimatedWidgetBaseState<AnimatedValueBuilder> createState() =>
      _AnimatedValueBuilderState();
}

/// The [State] for [AnimatedValueBuilder].
///
/// Handles the animation tween and widget building logic.
class _AnimatedValueBuilderState
    extends AnimatedWidgetBaseState<AnimatedValueBuilder> {
  /// The tween that interpolates between the old and new values.
  Tween<double>? _double;

  /// Updates the tween based on the new target value.
  ///
  /// If disableAnimation is true, creates a tween with equal begin and end values
  /// to disable the animation.
  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _double = (visitor(
      _double,
      widget.value,
      (dynamic value) => Tween<double>(begin: value),
    )! as Tween<double>);
    if (widget.disableAnimation) {
      _double = Tween<double>(
        begin: widget.value,
        end: widget.value,
      );
    }
  }

  /// Builds the widget using the current animation value.
  ///
  /// The animation value is passed to the builder function along with the current
  /// context and optional child widget.
  @override
  Widget build(BuildContext context) {
    final val = _double?.evaluate(animation) ?? widget.value;
    return widget.builder(context, val, widget.child);
  }
}
