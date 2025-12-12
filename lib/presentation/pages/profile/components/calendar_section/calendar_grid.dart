import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_day.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_week_header.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/models/calendar_day_model.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class CalendarGrid extends StatelessWidget with MainLayout, ProfileLayout {
  const CalendarGrid({
    required this.selectedMonth,
    required this.currentDate,
    required this.calendarThumbnails,
    this.onDayTap,
    this.maxWeeks = 6,
    this.dayAbbreviationLength = 2,
    super.key,
  });

  final DateTime selectedMonth;
  final DateTime currentDate;
  final Map<String, String> calendarThumbnails;
  final void Function(DateTime)? onDayTap;
  final int maxWeeks;
  final int dayAbbreviationLength;

  /// Calculates the weeks of the month with day models
  List<List<CalendarDayModel>> _calculateMonthWeeks() {
    const daysInWeek = 7;
    final weeks = <List<CalendarDayModel>>[];

    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final startOffset = startOfMonth.weekday - 1;
    final startDay = startOfMonth.day - startOffset;

    for (int weekIndex = 0; weekIndex < maxWeeks; weekIndex++) {
      final weekDays = <CalendarDayModel>[];
      bool hasCurrentMonthDay = false;

      for (int dayIndex = 0; dayIndex < daysInWeek; dayIndex++) {
        final totalDays = weekIndex * daysInWeek + dayIndex;
        final currentDay = DateTime(
          selectedMonth.year,
          selectedMonth.month,
          startDay + totalDays,
        );

        if (currentDay.month == selectedMonth.month) {
          hasCurrentMonthDay = true;
          break;
        }
      }

      if (hasCurrentMonthDay) {
        for (int dayIndex = 0; dayIndex < daysInWeek; dayIndex++) {
          final totalDays = weekIndex * daysInWeek + dayIndex;
          final currentDay = DateTime(
            selectedMonth.year,
            selectedMonth.month,
            startDay + totalDays,
          );

          final dateKey =
              '${currentDay.year}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}';
          final thumbnailUrl = calendarThumbnails[dateKey];

          weekDays.add(
            CalendarDayModel(
              date: currentDay,
              isCurrentMonth: currentDay.month == selectedMonth.month,
              isFuture: DateFormatter.isFutureDay(currentDay, currentDate),
              hasContent: thumbnailUrl != null,
              thumbnailUrl: thumbnailUrl,
            ),
          );
        }
        weeks.add(weekDays);
      }
    }

    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _calculateMonthWeeks();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarWeekHeader(abbreviationLength: dayAbbreviationLength),
          SizedBox(height: verticalMargin),

          ...weeks.map((weekDays) => _buildWeekRow(weekDays)),

          SizedBox(height: calendarBottomSpacing),
        ],
      ),
    );
  }

  Widget _buildWeekRow(List<CalendarDayModel> weekDays) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: weekDays
            .map(
              (dayData) => Expanded(
                child: CalendarDay(dayData: dayData, onTap: onDayTap),
              ),
            )
            .toList(),
      ),
    );
  }
}
