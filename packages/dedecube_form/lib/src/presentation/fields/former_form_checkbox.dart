import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A checkbox field that binds to a [FormerControl] using [reactive.ReactiveCheckbox].
class FormerFormCheckbox extends StatelessWidget {
  const FormerFormCheckbox({
    required this.control,
    super.key,
    this.tristate = false,
    this.activeColor,
    this.checkColor,
    this.focusColor,
    this.hoverColor,
    this.mouseCursor,
    this.materialTapTargetSize,
    this.visualDensity,
    this.autofocus = false,
    this.fillColor,
    this.overlayColor,
    this.splashRadius,
    this.focusNode,
    this.shape,
    this.side,
    this.onChanged,
    this.showErrors,
  });

  final FormerControl<bool> control;
  final bool tristate;
  final Color? activeColor;
  final Color? checkColor;
  final Color? focusColor;
  final Color? hoverColor;
  final MouseCursor? mouseCursor;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final bool autofocus;
  final WidgetStateProperty<Color?>? fillColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final FocusNode? focusNode;
  final OutlinedBorder? shape;
  final BorderSide? side;

  /// Callback when the checkbox value changes.
  final reactive.ReactiveFormFieldCallback<bool>? onChanged;

  /// Determines when to show error text.
  final reactive.ShowErrorsFunction<bool>? showErrors;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveCheckbox(
      formControl: control.internal,
      tristate: tristate,
      activeColor: activeColor,
      checkColor: checkColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      mouseCursor: mouseCursor,
      materialTapTargetSize: materialTapTargetSize,
      visualDensity: visualDensity,
      autofocus: autofocus,
      fillColor: fillColor,
      overlayColor: overlayColor,
      splashRadius: splashRadius,
      focusNode: focusNode,
      shape: shape,
      side: side,
      onChanged: onChanged,
      showErrors: showErrors,
    );
  }
}
