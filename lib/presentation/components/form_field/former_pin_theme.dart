import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:flutter/material.dart';

FormerPinTheme formerPinTheme(BuildContext context, {bool hasError = false}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return FormerPinTheme(
    fieldHeight: 52,
    fieldWidth: 50,
    shape: FormerPinCodeFieldShape.box,
    borderRadius: BorderRadius.circular(16),
    borderWidth: 0.5,
    activeColor: Colors.white.withValues(alpha: 0.2),
    selectedColor: MainColors.accent.withValues(alpha: 0.5),
    inactiveColor: Colors.white.withValues(alpha: 0.1),
    errorBorderColor: colorScheme.error,
    activeFillColor: MainColors.accent.withValues(alpha: 0.15),
    selectedFillColor: MainColors.accent.withValues(alpha: 0.2),
    inactiveFillColor: MainColors.accent.withValues(alpha: 0.1),
    disabledColor: Colors.transparent,
  );
}
