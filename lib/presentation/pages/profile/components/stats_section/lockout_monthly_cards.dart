import 'package:cloudless/core/features/lockout/data/dtos/lockout_daily_stats_dto.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/stats_card.dart';
import 'package:flutter/material.dart';

/// Displays a 2x2 grid of weekly summary stats derived from the daily stats.
class LockoutWeekSummaryCards extends StatelessWidget {
  const LockoutWeekSummaryCards({
    required this.dailyStats,
    required this.scale,
    super.key,
  });

  final List<LockoutDailyStatsDto> dailyStats;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // Aggregate from the 7-day daily stats
    var totalMinutes = 0;
    var totalSessions = 0;
    var maxMinutes = 0;
    var scoreSum = 0.0;
    var scoreCount = 0;

    for (final stat in dailyStats) {
      totalMinutes += stat.minutes;
      totalSessions += stat.sessionCount;
      if (stat.minutes > maxMinutes) maxMinutes = stat.minutes;
      if (stat.avgScore != null && stat.sessionCount > 0) {
        scoreSum += stat.avgScore! * stat.sessionCount;
        scoreCount += stat.sessionCount;
      }
    }

    final totalHours = '${(totalMinutes / 60).toStringAsFixed(1)}h';
    final avgScore = scoreCount > 0
        ? (scoreSum / scoreCount).toStringAsFixed(0)
        : '—';
    final sessions = totalSessions.toString();
    final lh = maxMinutes ~/ 60;
    final lm = maxMinutes % 60;
    final longest = lh > 0 ? '${lh}h ${lm}m' : '${lm}m';

    final s = scale;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8 * s,
      crossAxisSpacing: 8 * s,
      childAspectRatio: 2.8,
      children: [
        StatsCard(label: 'Total Hours', value: totalHours, scale: s),
        StatsCard(label: 'Avg Score', value: avgScore, scale: s),
        StatsCard(label: 'Sessions', value: sessions, scale: s),
        StatsCard(label: 'Longest', value: longest, scale: s),
      ],
    );
  }
}
