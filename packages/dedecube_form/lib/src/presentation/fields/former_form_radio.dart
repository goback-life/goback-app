import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A radio button that binds to a [FormerControl] using [reactive.ReactiveRadio].
class FormerFormRadio<T> extends StatelessWidget {
  const FormerFormRadio({
    required this.control,
    required this.value,
    super.key,
    this.activeColor,
    this.focusColor,
    this.hoverColor,
    this.fillColor,
    this.overlayColor,
    this.mouseCursor,
    this.materialTapTargetSize,
    this.visualDensity,
    this.splashRadius,
    this.autofocus = false,
    this.toggleable = false,
    this.focusNode,
    this.onChanged,
  });

  /// The [FormerControl<T>] that this radio button binds to.
  final FormerControl<T> control;

  /// The value represented by this radio button.
  final T value;

  /// The color to use when this radio button is selected.
  final Color? activeColor;

  /// The color of the radio button when it has focus.
  final Color? focusColor;

  /// The color of the radio button when hovered.
  final Color? hoverColor;

  /// The fill color of the radio button.
  final WidgetStateProperty<Color?>? fillColor;

  /// The overlay color for the radio button.
  final WidgetStateProperty<Color?>? overlayColor;

  /// The cursor for the radio button.
  final MouseCursor? mouseCursor;

  /// Configures the tap target size.
  final MaterialTapTargetSize? materialTapTargetSize;

  /// Configures the visual density.
  final VisualDensity? visualDensity;

  /// The splash radius for the radio button.
  final double? splashRadius;

  /// Whether this radio button should focus automatically.
  final bool autofocus;

  /// Whether the radio button is toggleable.
  final bool toggleable;

  /// The focus node for this radio button.
  final FocusNode? focusNode;

  /// Callback when the radio value changes.
  final reactive.ReactiveFormFieldCallback<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveRadio<T>(
      formControl: control.internal,
      value: value,
      activeColor: activeColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      fillColor: fillColor,
      overlayColor: overlayColor,
      mouseCursor: mouseCursor,
      materialTapTargetSize: materialTapTargetSize,
      visualDensity: visualDensity,
      splashRadius: splashRadius,
      autofocus: autofocus,
      toggleable: toggleable,
      focusNode: focusNode,
      onChanged: onChanged,
    );
  }
}
