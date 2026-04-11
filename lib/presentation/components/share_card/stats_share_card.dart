import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_bar_chart_painter.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Branded card for sharing weekly stats to external platforms.
/// Sized at 360x450 logical (4:5 ratio → 1080x1350 at 3x).
class StatsShareCard extends StatelessWidget {
  const StatsShareCard({
    required this.totalHours,
    required this.avgScore,
    required this.sessions,
    required this.longest,
    required this.username,
    required this.weekLabel,
    required this.dailyMinutes,
    super.key,
  });

  final String totalHours;
  final String avgScore;
  final String sessions;
  final String longest;
  final String username;
  final String weekLabel;
  final List<int> dailyMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 450,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: MainColors.dark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'remember boredom?',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: MainColors.white.withValues(alpha: 0.6),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Assets.svg.logoApp.render(height: 14),
            const SizedBox(height: 4),
            Text(
              weekLabel,
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: MainColors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: LockoutLineChartPainter(dailyMinutes: dailyMinutes),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map(
                    (d) => Text(
                      d,
                      style: TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        color: MainColors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(label: 'Total Hours', value: totalHours),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(label: 'Avg Score', value: avgScore),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatTile(label: 'Sessions', value: sessions),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(label: 'Longest', value: longest),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              username.isNotEmpty
                  ? 'offline time - @$username'
                  : 'offline time',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: MainColors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: MainColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: MainColors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
