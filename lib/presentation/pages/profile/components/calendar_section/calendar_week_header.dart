import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class CalendarWeekHeader extends StatelessWidget
    with MainLayout, ProfileLayout {
  const CalendarWeekHeader({this.abbreviationLength = 2, super.key});

  final int abbreviationLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final weekDays = DateFormatter.getWeekDayAbbreviations(
      translator.currentLocale.toString(),
      abbreviationLength: abbreviationLength,
    );

    return Row(
      children: weekDays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
