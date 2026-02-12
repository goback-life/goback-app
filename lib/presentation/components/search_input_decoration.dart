import 'package:cloudless/presentation/assets/assets.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

InputDecoration searchInputDecoration(
  BuildContext context,
  String? key,
  String searchQuery,
  VoidCallback onClearPressed,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return InputDecoration(
    hintText: translator.translate('components.searchbar.search_placeholder'),
    hintStyle: textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.shadow,
      fontWeight: FontWeight.w500,
    ),
    prefixIcon: SizedBox(
      width: 24,
      height: 24,
      child: Center(child: Assets.svg.search.render(width: 24, height: 24)),
    ),
    suffixIcon: searchQuery.isNotEmpty
        ? GestureDetector(
            onTap: onClearPressed,
            child: SizedBox(
              width: 25,
              height: 25,
              child: Center(
                child: Assets.svg.clean.render(
                  width: 25,
                  height: 25,
                  colorFilter: colorScheme.shadow.asSrcIn,
                ),
              ),
            ),
          )
        : null,
    filled: true,
    fillColor: Colors.transparent,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide.none,
    ),
  );
}
