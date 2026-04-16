import 'dart:async';

import 'package:cloudless/core/features/lockout/data/dtos/lockout_daily_stats_dto.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_bar_chart_painter.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Returns the Monday of the week containing [date].
DateTime _mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Formats minutes as "Xh Ym".
String _formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Earliest Monday within the 4-week retention window.
DateTime _earliestMonday() {
  final cutoff = DateTime.now().subtract(const Duration(days: 27));
  return _mondayOf(cutoff);
}

class LockoutLineChart extends HookWidget {
  const LockoutLineChart({
    required this.userId,
    required this.scale,
    required this.weekStart,
    required this.dailyStats,
    required this.onWeekChanged,
    super.key,
  });

  final String userId;
  final double scale;
  final DateTime weekStart;
  final List<LockoutDailyStatsDto> dailyStats;
  final ValueChanged<DateTime> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    final highlightIndex = useState(-1);

    final dailyMinutes = <int>[0, 0, 0, 0, 0, 0, 0];
    for (var i = 0; i < dailyStats.length && i < 7; i++) {
      dailyMinutes[i] = dailyStats[i].minutes;
    }

    final now = _mondayOf(DateTime.now());
    final earliest = _earliestMonday();
    final isCurrentWeek = weekStart == now;
    final isOldestWeek = !weekStart.isAfter(earliest);

    void goBack() {
      if (isOldestWeek) return;
      onWeekChanged(weekStart.subtract(const Duration(days: 7)));
      highlightIndex.value = -1;
    }

    void goForward() {
      if (isCurrentWeek) return;
      onWeekChanged(weekStart.add(const Duration(days: 7)));
      highlightIndex.value = -1;
    }

    // Auto-dismiss tooltip after 3s
    useEffect(() {
      if (highlightIndex.value < 0) return null;
      final timer = Timer(const Duration(seconds: 3), () {
        highlightIndex.value = -1;
      });
      return timer.cancel;
    }, [highlightIndex.value]);

    // Week label: "Mar 3 – Mar 9"
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    final weekLabel = '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}';

    final s = scale;
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontFamily: MainFontFamilies.quicksand,
      fontWeight: FontWeight.w500,
      fontSize: 12 * s,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
    );

    // Tooltip text
    String? tooltipText;
    if (highlightIndex.value >= 0 && highlightIndex.value < dailyStats.length) {
      final stat = dailyStats[highlightIndex.value];
      if (stat.minutes > 0) {
        final parts = <String>[
          _formatMinutes(stat.minutes),
          'over ${stat.sessionCount} lockout${stat.sessionCount == 1 ? '' : 's'}',
        ];
        if (stat.avgScore != null) {
          parts.add('avg score ${stat.avgScore!.toStringAsFixed(0)}');
        }
        tooltipText = parts.join(', ');
      }
    }

    return Column(
      children: [
        // Week navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: isOldestWeek ? null : goBack,
              child: Icon(
                Icons.chevron_left,
                color: isOldestWeek
                    ? colorScheme.onSurface.withValues(alpha: 0.2)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                size: 24 * s,
              ),
            ),
            SizedBox(width: 8 * s),
            Text(
              weekLabel,
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w600,
                fontSize: 14 * s,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 8 * s),
            GestureDetector(
              onTap: isCurrentWeek ? null : goForward,
              child: Icon(
                Icons.chevron_right,
                color: isCurrentWeek
                    ? colorScheme.onSurface.withValues(alpha: 0.2)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                size: 24 * s,
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * s),

        // Line chart + swipe
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! > 0) {
                goBack();
              } else if (details.primaryVelocity! < 0) {
                goForward();
              }
            },
            onTapDown: (details) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox == null) return;
              final localX = details.localPosition.dx;
              final width = renderBox.size.width;
              final index = (localX / width * 7).floor().clamp(0, 6);
              highlightIndex.value = index;
            },
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              size: Size.infinite,
              painter: LockoutLineChartPainter(
                dailyMinutes: dailyMinutes,
                highlightIndex: highlightIndex.value,
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * s),

        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            'M',
            'T',
            'W',
            'T',
            'F',
            'S',
            'S',
          ].map((d) => Text(d, style: labelStyle)).toList(),
        ),

        // Tooltip
        SizedBox(
          height: 20 * s,
          child: tooltipText != null
              ? Text(
                  tooltipText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 11 * s,
                    color: MainColors.accent,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
