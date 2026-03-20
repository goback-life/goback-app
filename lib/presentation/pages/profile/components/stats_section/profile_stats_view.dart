import 'package:cloudless/core/features/lockout/data/dtos/lockout_daily_stats_dto.dart';
import 'package:cloudless/core/features/lockout/domain/providers/get_lockout_daily_stats_provider.dart';
import 'package:cloudless/core/features/share/data/services/share_card_capture_service.dart';
import 'package:cloudless/presentation/components/share_card/stats_share_card.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_bar_chart.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_monthly_cards.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Returns the Monday of the week containing [date].
DateTime _mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

class ProfileStatsView extends HookConsumerWidget {
  const ProfileStatsView({
    required this.userId,
    required this.scale,
    this.username = '',
    super.key,
  });

  final String userId;
  final double scale;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final weekStart = useState(_mondayOf(DateTime.now()));

    final statsAsync = ref.watch(
      getLockoutDailyStatsProvider(
        userId: userId,
        weekStart: weekStart.value,
      ),
    );

    final dailyStats = <LockoutDailyStatsDto>[];
    statsAsync.whenData((result) {
      result.fold((stats) => dailyStats.addAll(stats), (_) {});
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: LockoutLineChart(
                  userId: userId,
                  scale: s,
                  weekStart: weekStart.value,
                  dailyStats: dailyStats,
                  onWeekChanged: (w) => weekStart.value = w,
                ),
              ),
              SizedBox(height: 16 * s),
              LockoutWeekSummaryCards(dailyStats: dailyStats, scale: s),
              SizedBox(height: 16 * s),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _shareStats(
                context,
                dailyStats,
                weekStart.value,
              ),
              child: Padding(
                padding: EdgeInsets.all(8 * s),
                child: Icon(
                  Icons.ios_share,
                  size: 18 * s,
                  color: MainColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareStats(
    BuildContext context,
    List<LockoutDailyStatsDto> dailyStats,
    DateTime weekStart,
  ) async {
    // Aggregate stats (mirrors LockoutWeekSummaryCards logic)
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
    final avgScore =
        scoreCount > 0 ? (scoreSum / scoreCount).toStringAsFixed(0) : '—';
    final sessions = totalSessions.toString();
    final lh = maxMinutes ~/ 60;
    final lm = maxMinutes % 60;
    final longest = lh > 0 ? '${lh}h ${lm}m' : '${lm}m';

    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    final weekLabel = '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}';

    // Build daily minutes array for chart
    final dailyMinutesList = <int>[0, 0, 0, 0, 0, 0, 0];
    for (var i = 0; i < dailyStats.length && i < 7; i++) {
      dailyMinutesList[i] = dailyStats[i].minutes;
    }

    if (!context.mounted) return;

    await ShareCardCaptureService().captureAndShare(
      context,
      StatsShareCard(
        totalHours: totalHours,
        avgScore: avgScore,
        sessions: sessions,
        longest: longest,
        username: username,
        weekLabel: weekLabel,
        dailyMinutes: dailyMinutesList,
      ),
    );
  }
}
