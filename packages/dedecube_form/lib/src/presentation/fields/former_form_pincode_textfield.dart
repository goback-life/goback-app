import 'dart:async';

import 'package:dedecube_form/src/domain/former_control.dart';
import 'package:dedecube_form/src/domain/typedefs/former_form_pincode_typedef.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart' as reactive;
import 'package:reactive_pin_code_fields/reactive_pin_code_fields.dart'
    as reactive;

/// A pin text field that binds to a [FormerControl] using [reactive.ReactivePinCodeTextField].
class FormerFormPincodeTextfield<T> extends StatelessWidget {
  const FormerFormPincodeTextfield({
    required this.control,
    required this.length,
    super.key,
    this.obscureText = false,
    this.boxShadows,
    this.obscuringCharacter = '●',
    this.obscuringWidget,
    this.useHapticFeedback = false,
    this.hapticFeedbackTypes = FormerHapticFeedbackTypes.light,
    this.blinkWhenObscuring = false,
    this.blinkDuration = const Duration(milliseconds: 500),
    this.textStyle,
    this.pastedTextStyle,
    this.backgroundColor,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.animationType = FormerPinAnimationTypes.slide,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
    this.keyboardType = TextInputType.visiblePassword,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters = const <TextInputFormatter>[],
    this.controller,
    this.enableActiveFill = false,
    this.autoDismissKeyboard = true,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.done,
    this.errorAnimationController,
    this.beforeTextPaste,
    this.onTap,
    this.dialogConfig,
    this.pinTheme = FormerPinThemeDefaults.defaults,
    this.keyboardAppearance,
    this.validator,
    this.onSaved,
    this.errorTextSpace = 16,
    this.enablePinAutofill = true,
    this.errorAnimationDuration = 500,
    this.showCursor = true,
    this.cursorColor,
    this.cursorWidth = 2,
    this.cursorHeight,
    this.onAutoFillDisposeAction = AutofillContextAction.commit,
    this.useExternalAutoFillGroup = false,
    this.hintCharacter,
    this.hintStyle,
    this.readOnly = false,
    this.textGradient,
    this.scrollPadding = const EdgeInsets.all(20),
    this.errorTextDirection = TextDirection.ltr,
    this.errorTextMargin = EdgeInsets.zero,
    this.autoUnfocus = true,
    this.onSubmitted,
    this.onCompleted,
    this.validationMessages,
    this.showErrors,
  });

  final FormerControl<T> control;
  final bool obscureText;
  final List<BoxShadow>? boxShadows;
  final int length;
  final String obscuringCharacter;
  final Widget? obscuringWidget;
  final bool useHapticFeedback;
  final FormerHapticFeedbackType hapticFeedbackTypes;
  final bool blinkWhenObscuring;
  final Duration blinkDuration;
  final TextStyle? textStyle;
  final TextStyle? pastedTextStyle;
  final Color? backgroundColor;
  final MainAxisAlignment mainAxisAlignment;
  final FormerPinAnimationType animationType;
  final Duration animationDuration;
  final Curve animationCurve;
  final TextInputType keyboardType;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter> inputFormatters;
  final TextEditingController? controller;
  final bool enableActiveFill;
  final bool autoDismissKeyboard;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final StreamController<FormerErrorAnimationType>? errorAnimationController;
  final bool Function(String? text)? beforeTextPaste;
  final Function? onTap;
  final FormerPinDialogConfig? dialogConfig;
  final FormerPinTheme pinTheme;
  final Brightness? keyboardAppearance;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final double errorTextSpace;
  final bool enablePinAutofill;
  final int errorAnimationDuration;
  final bool showCursor;
  final Color? cursorColor;
  final double cursorWidth;
  final double? cursorHeight;
  final AutofillContextAction onAutoFillDisposeAction;
  final bool useExternalAutoFillGroup;
  final String? hintCharacter;
  final TextStyle? hintStyle;
  final bool readOnly;
  final Gradient? textGradient;
  final EdgeInsets scrollPadding;
  final TextDirection errorTextDirection;
  final EdgeInsets errorTextMargin;
  final bool autoUnfocus;

  /// Called when the user submits the field (e.g. hits "done").
  final void Function(FormerControl<T> control)? onSubmitted;

  /// Called when editing is complete.
  final void Function(FormerControl<T> control)? onCompleted;

  /// Validation messages to show for different error codes.
  final Map<String, String Function(Object error)>? validationMessages;

  /// Determines when to show error text.
  final reactive.ShowErrorsFunction? showErrors;

  @override
  Widget build(BuildContext context) {
    final internalControl = control.internal;

    bool hasError = false;
    if (showErrors != null) {
      hasError = showErrors!(internalControl);
    } else {
      hasError = internalControl.invalid &&
          (internalControl.dirty || internalControl.touched);
    }

    final effectivePinTheme = reactive.PinTheme(
      shape: pinTheme.shape,
      borderRadius: pinTheme.borderRadius,
      fieldHeight: pinTheme.fieldHeight,
      fieldWidth: pinTheme.fieldWidth,
      activeColor: hasError ? pinTheme.errorBorderColor : pinTheme.activeColor,
      selectedColor:
          hasError ? pinTheme.errorBorderColor : pinTheme.selectedColor,
      inactiveColor:
          hasError ? pinTheme.errorBorderColor : pinTheme.inactiveColor,
      activeFillColor: pinTheme.activeFillColor,
      inactiveFillColor: pinTheme.inactiveFillColor,
      selectedFillColor: pinTheme.selectedFillColor,
      disabledColor: pinTheme.disabledColor,
      errorBorderColor: pinTheme.errorBorderColor,
      borderWidth: pinTheme.borderWidth,
    );

    return reactive.ReactivePinCodeTextField<T>(
      formControl: internalControl,
      obscureText: obscureText,
      boxShadows: boxShadows,
      length: length,
      obscuringCharacter: obscuringCharacter,
      obscuringWidget: obscuringWidget,
      useHapticFeedback: useHapticFeedback,
      hapticFeedbackTypes: hapticFeedbackTypes,
      blinkWhenObscuring: blinkWhenObscuring,
      blinkDuration: blinkDuration,
      textStyle: textStyle,
      pastedTextStyle: pastedTextStyle,
      backgroundColor: backgroundColor,
      mainAxisAlignment: mainAxisAlignment,
      animationType: animationType,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      keyboardType: keyboardType,
      autofocus: autofocus,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      controller: controller,
      enableActiveFill: enableActiveFill,
      autoDismissKeyboard: autoDismissKeyboard,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      errorAnimationController: errorAnimationController,
      beforeTextPaste: beforeTextPaste,
      onTap: onTap,
      dialogConfig: dialogConfig,
      pinTheme: effectivePinTheme,
      keyboardAppearance: keyboardAppearance,
      validator: validator,
      onSaved: onSaved,
      errorTextSpace: errorTextSpace,
      enablePinAutofill: enablePinAutofill,
      errorAnimationDuration: errorAnimationDuration,
      showCursor: showCursor,
      cursorColor: cursorColor,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      onAutoFillDisposeAction: onAutoFillDisposeAction,
      useExternalAutoFillGroup: useExternalAutoFillGroup,
      hintCharacter: hintCharacter,
      hintStyle: hintStyle,
      readOnly: readOnly,
      textGradient: textGradient,
      scrollPadding: scrollPadding,
      errorTextDirection: errorTextDirection,
      errorTextMargin: errorTextMargin,
      autoUnfocus: autoUnfocus,
      validationMessages: validationMessages,
      onSubmitted: (_) => onSubmitted?.call(control),
      onCompleted: (_) => onCompleted?.call(control),
      showErrors: showErrors,
    );
  }
}
