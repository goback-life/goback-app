import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A checkbox tile that binds to a [FormerControl] using [reactive.ReactiveCheckboxListTile].
class FormerFormCheckboxTile extends StatelessWidget {
  const FormerFormCheckboxTile({
    required this.control,
    super.key,
    this.title,
    this.subtitle,
    this.activeColor,
    this.checkColor,
    this.dense,
    this.secondary,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.contentPadding,
    this.tristate = false,
    this.selectedTileColor,
    this.tileColor,
    this.shape,
    this.selected = false,
    this.visualDensity,
    this.enableFeedback,
    this.checkboxShape,
    this.side,
    this.mouseCursor,
    this.fillColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.onFocusChange,
    this.showErrors,
  });

  final FormerControl<bool> control;
  final Widget? title;
  final Widget? subtitle;
  final Color? activeColor;
  final Color? checkColor;
  final bool? dense;
  final Widget? secondary;
  final ListTileControlAffinity controlAffinity;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final bool tristate;
  final Color? selectedTileColor;
  final Color? tileColor;
  final ShapeBorder? shape;
  final bool selected;
  final VisualDensity? visualDensity;
  final bool? enableFeedback;
  final OutlinedBorder? checkboxShape;
  final BorderSide? side;
  final MouseCursor? mouseCursor;
  final WidgetStateProperty<Color?>? fillColor;
  final Color? hoverColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;

  /// Callback when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Determines when to show error text.
  final reactive.ShowErrorsFunction<bool>? showErrors;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveCheckboxListTile(
      formControl: control.internal,
      activeColor: activeColor,
      checkColor: checkColor,
      title: title,
      subtitle: subtitle,
      dense: dense,
      secondary: secondary,
      controlAffinity: controlAffinity,
      autofocus: autofocus,
      contentPadding: contentPadding,
      tristate: tristate,
      selectedTileColor: selectedTileColor,
      tileColor: tileColor,
      shape: shape,
      selected: selected,
      visualDensity: visualDensity,
      enableFeedback: enableFeedback,
      checkboxShape: checkboxShape,
      side: side,
      mouseCursor: mouseCursor,
      fillColor: fillColor,
      hoverColor: hoverColor,
      overlayColor: overlayColor,
      splashRadius: splashRadius,
      materialTapTargetSize: materialTapTargetSize,
      onFocusChange: onFocusChange,
      showErrors: showErrors,
    );
  }
}
