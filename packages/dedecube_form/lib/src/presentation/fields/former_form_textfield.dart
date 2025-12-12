import 'dart:ui' as ui;

import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;

/// A text field that binds to a [FormerControl] using [reactive.ReactiveTextField].
class FormerFormTextfield<T> extends StatelessWidget {
  const FormerFormTextfield({
    required this.control,
    super.key,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofocus = false,
    this.readOnly = false,
    this.contextMenuBuilder,
    this.showCursor,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLengthEnforcement,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.inputFormatters,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.buildCounter,
    this.scrollPhysics,
    this.autofillHints,
    this.mouseCursor,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onAppPrivateCommand,
    this.restorationId,
    this.scrollController,
    this.selectionControls,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.controller,
    this.clipBehavior = Clip.hardEdge,
    this.enableIMEPersonalizedLearning = true,
    this.scribbleEnabled = true,
    this.undoController,
    this.cursorOpacityAnimates,
    this.onTapOutside,
    this.contentInsertionConfiguration,
    this.canRequestFocus = true,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validationMessages,
    this.showErrors,
  });

  final FormerControl<T> control;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool autofocus;
  final bool readOnly;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final bool? showCursor;
  final bool obscureText;
  final String obscuringCharacter;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final MouseCursor? mouseCursor;
  final DragStartBehavior dragStartBehavior;
  final AppPrivateCommandCallback? onAppPrivateCommand;
  final String? restorationId;
  final ScrollController? scrollController;
  final TextSelectionControls? selectionControls;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
  final TextEditingController? controller;
  final Clip clipBehavior;
  final bool enableIMEPersonalizedLearning;
  final bool scribbleEnabled;
  final UndoHistoryController? undoController;
  final bool? cursorOpacityAnimates;
  final TapRegionCallback? onTapOutside;
  final ContentInsertionConfiguration? contentInsertionConfiguration;
  final bool canRequestFocus;
  final SpellCheckConfiguration? spellCheckConfiguration;
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// Called when the control value changes.
  final void Function(FormerControl<T> control)? onChanged;

  /// Called when the user submits the field (e.g. hits "done").
  final void Function(FormerControl<T> control)? onSubmitted;

  /// Called when editing is complete.
  final void Function(FormerControl<T> control)? onEditingComplete;

  /// Validation messages to show for different error codes.
  final Map<String, String Function(Object error)>? validationMessages;

  /// Determines when to show error text.
  final reactive.ShowErrorsFunction? showErrors;

  @override
  Widget build(BuildContext context) {
    return reactive.ReactiveTextField<T>(
      formControl: control.internal,
      decoration: decoration,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: style,
      strutStyle: strutStyle,
      textDirection: textDirection,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      autofocus: autofocus,
      readOnly: readOnly,
      contextMenuBuilder: contextMenuBuilder,
      showCursor: showCursor,
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType ??
          (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled),
      smartQuotesType: smartQuotesType ??
          (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled),
      enableSuggestions: enableSuggestions,
      maxLengthEnforcement: maxLengthEnforcement,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      scrollPadding: scrollPadding,
      keyboardAppearance: keyboardAppearance,
      enableInteractiveSelection: enableInteractiveSelection,
      buildCounter: buildCounter,
      autofillHints: autofillHints,
      mouseCursor: mouseCursor,
      dragStartBehavior: dragStartBehavior,
      onAppPrivateCommand: onAppPrivateCommand,
      restorationId: restorationId,
      scrollController: scrollController,
      selectionControls: selectionControls,
      selectionHeightStyle: selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle,
      clipBehavior: clipBehavior,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      undoController: undoController,
      cursorOpacityAnimates: cursorOpacityAnimates,
      onTapOutside: onTapOutside,
      contentInsertionConfiguration: contentInsertionConfiguration,
      canRequestFocus: canRequestFocus,
      spellCheckConfiguration: spellCheckConfiguration,
      magnifierConfiguration: magnifierConfiguration,
      validationMessages: validationMessages,
      onChanged: (_) => onChanged?.call(control),
      onSubmitted: (_) => onSubmitted?.call(control),
      onEditingComplete: (_) => onEditingComplete?.call(control),
      showErrors: showErrors,
    );
  }
}
