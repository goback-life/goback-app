import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A radio list tile that binds to a [FormerControl] using [reactive.ReactiveRadioListTile].
class FormerFormRadioTile<T> extends StatelessWidget {
  const FormerFormRadioTile({
    required this.control,
    required this.value,
    super.key,
    this.activeColor,
    this.selectedTileColor,
    this.tileColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.contentPadding,
    this.toggleable = false,
    this.shape,
    this.autofocus = false,
    this.selected = false,
    this.visualDensity,
    this.enableFeedback,
    this.focusNode,
    this.onChanged,
    this.mouseCursor,
    this.fillColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.onFocusChange,
  });

  final FormerControl<T> control;
  final T value;
  final Color? activeColor;
  final Color? selectedTileColor;
  final Color? tileColor;
  final Widget? title;
  final Widget? subtitle;
  final bool isThreeLine;
  final bool? dense;
  final Widget? secondary;
  final ListTileControlAffinity controlAffinity;
  final EdgeInsetsGeometry? contentPadding;
  final bool toggleable;
  final ShapeBorder? shape;
  final bool autofocus;
  final bool selected;
  final VisualDensity? visualDensity;
  final bool? enableFeedback;
  final FocusNode? focusNode;
  final reactive.ReactiveFormFieldCallback<T>? onChanged;
  final MouseCursor? mouseCursor;
  final WidgetStateProperty<Color?>? fillColor;
  final Color? hoverColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? splashRadius;
  final MaterialTapTargetSize? materialTapTargetSize;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveRadioListTile<T>(
      formControl: control.internal,
      value: value,
      activeColor: activeColor,
      selectedTileColor: selectedTileColor,
      tileColor: tileColor,
      title: title,
      subtitle: subtitle,
      isThreeLine: isThreeLine,
      dense: dense,
      secondary: secondary,
      controlAffinity: controlAffinity,
      contentPadding: contentPadding,
      toggleable: toggleable,
      shape: shape,
      autofocus: autofocus,
      selected: selected,
      visualDensity: visualDensity,
      enableFeedback: enableFeedback,
      focusNode: focusNode,
      onChanged: onChanged,
      mouseCursor: mouseCursor,
      fillColor: fillColor,
      hoverColor: hoverColor,
      overlayColor: overlayColor,
      splashRadius: splashRadius,
      materialTapTargetSize: materialTapTargetSize,
      onFocusChange: onFocusChange,
    );
  }
}
