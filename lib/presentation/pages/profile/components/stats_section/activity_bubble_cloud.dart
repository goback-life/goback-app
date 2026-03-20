import 'package:cloudless/core/features/lockout/data/dtos/lockout_activity_stats_dto.dart';
import 'package:cloudless/core/features/lockout/domain/providers/get_lockout_activity_stats_provider.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/activity_bubble_cloud_painter.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Preset activity keys → emoji. Mirrors manual_lockout_dialog.dart.
const _kPresets = {
  'sport': '\u{1F3C3}',
  'music': '\u{1F3B5}',
  'friends': '\u{1F91D}',
  'relax': '\u{1F9D8}',
  'studying': '\u{1F4DA}',
};

/// Default emoji for custom (non-preset) activities.
const _kDefaultEmoji = '\u{2B50}'; // ⭐

class ActivityBubbleCloud extends HookConsumerWidget {
  const ActivityBubbleCloud({
    required this.userId,
    required this.scale,
    super.key,
  });

  final String userId;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final statsAsync = ref.watch(
      getLockoutActivityStatsProvider(userId: userId),
    );

    final activities = <LockoutActivityStatsDto>[];
    String? errorMsg;
    final isLoading = statsAsync.isLoading;
    statsAsync.whenData((result) {
      result.fold(
        (stats) => activities.addAll(stats),
        (e) => errorMsg = e.toString(),
      );
    });
    statsAsync.whenOrNull(error: (e, _) => errorMsg = e.toString());

    // Build reverse lookup: translated label → preset key
    final labelToKey = <String, String>{};
    for (final key in _kPresets.keys) {
      final label = translator.translate(
        'pages.manual_lockout.dialog.activities.$key',
      );
      labelToKey[label] = key;
    }

    // Convert DTOs to bubbles with emoji resolution
    final bubbles = activities.map((stat) {
      final presetKey = labelToKey[stat.actionText];
      final emoji = presetKey != null
          ? _kPresets[presetKey]!
          : _kDefaultEmoji;
      return ActivityBubble(
        label: stat.actionText,
        emoji: emoji,
        totalMinutes: stat.totalMinutes,
      );
    }).toList();

    if (isLoading) {
      return Center(
        child: Text(
          'Loading activities…',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 14 * s,
            color: MainColors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    if (errorMsg != null) {
      return Center(
        child: Text(
          'Error: $errorMsg',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 12 * s,
            color: MainColors.white.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (bubbles.isEmpty) {
      return Center(
        child: Text(
          'No activity data yet',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 14 * s,
            color: MainColors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: CustomPaint(
          size: Size.infinite,
          painter: ActivityBubbleCloudPainter(bubbles: bubbles),
        ),
      ),
    );
  }
}
