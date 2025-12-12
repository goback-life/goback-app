import 'package:dedecube_form/dedecube_form.dart';
import 'package:flutter/material.dart';

FormerPinTheme formerPinTheme(BuildContext context, {bool hasError = false}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return FormerPinTheme(
    fieldHeight: 50,
    fieldWidth: 40,
    shape: FormerPinCodeFieldShape.box,
    borderRadius: BorderRadius.circular(6),
    borderWidth: 0,
    activeColor: Colors.transparent,
    selectedColor: Colors.transparent,
    inactiveColor: Colors.transparent,
    errorBorderColor: colorScheme.error,
    activeFillColor: colorScheme.tertiaryContainer.withValues(alpha: 0.1),
    selectedFillColor: colorScheme.tertiaryContainer.withValues(alpha: 0.1),
    inactiveFillColor: colorScheme.tertiaryContainer.withValues(alpha: 0.1),
    disabledColor: colorScheme.tertiaryContainer.withValues(alpha: 0.1),
  );
}
