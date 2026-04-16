import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Glass pill overlay showing the currently visible post date.
///
/// Uses [GlassVariant.clear] for maximum transparency.
/// Fixed at top-center of the feed with safe-area padding.
class FeedDateOverlay extends StatelessWidget {
  const FeedDateOverlay({
    required this.displayDate,
    this.hasUnreadNotifications = false,
    this.postCount = 0,
    super.key,
  });

  final DateTime? displayDate;
  final bool hasUnreadNotifications;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    if (displayDate == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;
    final fontSize = FeedLayout.dateFontSize * s;
    final hPad = FeedLayout.dateOverlayHPadding * s;
    final vPad = FeedLayout.dateOverlayVPadding * s;

    final formatted = _formatDate(displayDate!);

    return AppGlassContainer(
      config: GlassConfig(
        variant: GlassVariant.clear,
        cornerRadius: FeedLayout.dateOverlayCornerRadius * s,
        tint: hasUnreadNotifications
            ? MainColors.red500.withValues(alpha: 0.35)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Text(
          formatted,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w400,
            fontSize: fontSize,
            color: postCount < 3 ? MainColors.dark : MainColors.white,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'yesterday';
    return DateFormat('d MMM yyyy').format(date).toLowerCase();
  }
}
