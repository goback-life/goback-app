import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CalendarHeader extends StatelessWidget with MainLayout, ProfileLayout {
  const CalendarHeader({
    required this.selectedMonth,
    required this.onPreviousMonth,
    super.key,
    this.onNextMonth,
  });

  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final locale = translator.currentLocale.toString();
    final monthName = DateFormatter.formatMonthName(selectedMonth, locale);

    final monthFormat = translator.translate(
      'pages.profile.calendar.month_format',
    );
    final displayText = monthFormat
        .replaceAll('{month}', monthName)
        .replaceAll('{year}', selectedMonth.year.toString());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onPreviousMonth,
            child: SizedBox(
              width: iconSize + 10,
              height: iconSize + 10,
              child: Center(
                child: Assets.svg.back.render(
                  height: iconSize,
                  width: iconSize,
                  colorFilter: colorScheme.primary.asSrcIn,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            displayText,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onNextMonth,
            child: SizedBox(
              width: iconSize + 10,
              height: iconSize + 10,
              child: Center(
                child: Assets.svg.next.render(
                  height: iconSize,
                  width: iconSize,
                  colorFilter: onNextMonth != null
                      ? colorScheme.primary.asSrcIn
                      : colorScheme.surface.withValues(alpha: 0.3).asSrcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
