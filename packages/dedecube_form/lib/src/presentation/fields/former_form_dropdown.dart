import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A dropdown field that binds to a [FormerControl] using [reactive.ReactiveDropdownField].
class FormerFormDropdown<T> extends StatelessWidget {
  const FormerFormDropdown({
    required this.control,
    required this.items,
    super.key,
    this.decoration = const InputDecoration(),
    this.selectedItemBuilder,
    this.hint,
    this.disabledHint,
    this.elevation = 8,
    this.style,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = true,
    this.isExpanded = false,
    this.readOnly = false,
    this.itemHeight,
    this.dropdownColor,
    this.focusColor,
    this.autofocus = false,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
    this.onTap,
    this.onChanged,
    this.validationMessages,
    this.showErrors,
  });

  final FormerControl<T> control;
  final List<DropdownMenuItem<T>> items;
  final InputDecoration decoration;
  final DropdownButtonBuilder? selectedItemBuilder;
  final Widget? hint;
  final Widget? disabledHint;
  final int elevation;
  final TextStyle? style;
  final Widget? icon;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double iconSize;
  final bool isDense;
  final bool isExpanded;
  final bool readOnly;
  final double? itemHeight;
  final Color? dropdownColor;
  final Color? focusColor;
  final bool autofocus;
  final double? menuMaxHeight;
  final bool? enableFeedback;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Called when the dropdown is tapped.
  final void Function(FormerControl<T> control)? onTap;

  /// Called when the value changes.
  final void Function(FormerControl<T> control)? onChanged;

  /// Validation messages to show for different error codes.
  final Map<String, String Function(Object error)>? validationMessages;

  /// Determines when to show error text.
  final reactive.ShowErrorsFunction<T>? showErrors;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveDropdownField<T>(
      formControl: control.internal,
      items: items,
      decoration: decoration,
      selectedItemBuilder: selectedItemBuilder,
      hint: hint,
      disabledHint: disabledHint,
      elevation: elevation,
      style: style,
      icon: icon,
      iconDisabledColor: iconDisabledColor,
      iconEnabledColor: iconEnabledColor,
      iconSize: iconSize,
      isDense: isDense,
      isExpanded: isExpanded,
      readOnly: readOnly,
      itemHeight: itemHeight,
      dropdownColor: dropdownColor,
      focusColor: focusColor,
      autofocus: autofocus,
      menuMaxHeight: menuMaxHeight,
      enableFeedback: enableFeedback,
      alignment: alignment,
      borderRadius: borderRadius,
      padding: padding,
      onTap: onTap != null ? (_) => onTap!(control) : null,
      onChanged: onChanged != null ? (_) => onChanged!(control) : null,
      validationMessages: validationMessages,
      showErrors: showErrors,
    );
  }
}
