import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeDateBadge extends StatelessWidget with MainLayout, HomeLayout {
  const HomeDateBadge({
    this.displayDate,
    super.key,
  });

  /// The date to display. If null, shows today's date.
  final DateTime? displayDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final locale = translator.currentLocale.toString();

    // Use displayDate if provided, otherwise use today
    final dateToShow = displayDate ?? DateTime.now();
    final formattedDate = DateFormatter.formatDayMonth(dateToShow, locale);

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
