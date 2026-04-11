import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_day.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/models/calendar_day_model.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class CalendarGrid extends StatelessWidget with MainLayout, ProfileLayout {
  const CalendarGrid({
    required this.selectedMonth,
    required this.currentDate,
    required this.calendarThumbnails,
    this.scale = 1.0,
    this.onDayTap,
    this.maxWeeks = 6,
    super.key,
  });

  final DateTime selectedMonth;
  final DateTime currentDate;
  final Map<String, String> calendarThumbnails;
  final double scale;
  final void Function(DateTime)? onDayTap;
  final int maxWeeks;

  List<List<CalendarDayModel>> _calculateMonthWeeks() {
    const daysInWeek = 7;
    final weeks = <List<CalendarDayModel>>[];

    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final startOffset = startOfMonth.weekday - 1;
    final startDay = startOfMonth.day - startOffset;

    for (int weekIndex = 0; weekIndex < maxWeeks; weekIndex++) {
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
        final weekDays = <CalendarDayModel>[];
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
    final gridW = calendarGridWidth * scale;

    return Center(
      child: SizedBox(
        width: gridW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < weeks.length; i++) ...[
              _buildWeekRow(weeks[i]),
              if (i < weeks.length - 1)
                SizedBox(height: (calendarRowSpacing - dayCellHeight) * scale),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRow(List<CalendarDayModel> weekDays) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays
          .map(
            (dayData) =>
                CalendarDay(dayData: dayData, scale: scale, onTap: onDayTap),
          )
          .toList(),
    );
  }
}
