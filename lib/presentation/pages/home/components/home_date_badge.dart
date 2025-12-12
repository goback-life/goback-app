import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeDateBadge extends StatelessWidget with MainLayout, HomeLayout {
  const HomeDateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final now = DateTime.now();
    final locale = translator.currentLocale.toString();

    final formattedDate = DateFormatter.formatDayMonth(now, locale);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dateBadgeHorizontalPadding,
        vertical: dateBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(dateBadgeBorderRadius),
      ),
      child: Text(
        formattedDate,
        style: textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primaryContainer,
        ),
      ),
    );
  }
}
