import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:styled_text/styled_text.dart';

class ObjectiveDescription extends StatelessWidget {
  const ObjectiveDescription({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return StyledText(
      text: translator.translate('pages.objective.description'),
      textAlign: TextAlign.start,
      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      tags: {
        'bold': StyledTextTag(
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      },
    );
  }
}
