import 'package:flutter/material.dart';

InputDecoration inputDecoration(BuildContext context, String? key) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return InputDecoration(
    contentPadding: const EdgeInsets.only(top: 12, left: 10),
    labelStyle: textTheme.titleSmall?.copyWith(color: colorScheme.secondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    filled: true,
    fillColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
  );
}
