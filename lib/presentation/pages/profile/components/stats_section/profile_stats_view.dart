import 'package:cloudless/core/features/lockout/data/dtos/lockout_daily_stats_dto.dart';
import 'package:cloudless/core/features/lockout/domain/providers/get_lockout_daily_stats_provider.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_bar_chart.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_monthly_cards.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Returns the Monday of the week containing [date].
DateTime _mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

class ProfileStatsView extends HookConsumerWidget {
  const ProfileStatsView({
    required this.userId,
    required this.scale,
    super.key,
  });

  final String userId;
  final double scale;

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
      child: Column(
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
    );
  }
}
