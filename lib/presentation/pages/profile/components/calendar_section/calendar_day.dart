import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/models/calendar_day_model.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class CalendarDay extends StatelessWidget with MainLayout, ProfileLayout {
  const CalendarDay({
    required this.dayData,
    this.scale = 1.0,
    this.onTap,
    super.key,
  });

  final CalendarDayModel dayData;
  final double scale;
  final void Function(DateTime)? onTap;

  @override
  Widget build(BuildContext context) {
    final cellW = dayCellWidth * scale;
    final cellH = dayCellHeight * scale;

    final hasThumbnail =
        dayData.thumbnailUrl != null && dayData.thumbnailUrl!.isNotEmpty;

    // Leading/trailing cells from other months: blank squircles (no numbers).
    if (!dayData.isCurrentMonth) {
      return SizedBox(width: cellW, height: cellH);
    }

    // Day number: white on populated (thumbnail) cells, dark on empty cells.
    Text dayText(Color color) => Text(
      dayData.day.toString(),
      style: TextStyle(
        fontFamily: MainFontFamilies.quicksand,
        fontWeight: FontWeight.w500,
        fontSize: dayFontSize * scale,
        letterSpacing: dayTracking * scale,
        color: color,
      ),
    );

    Widget cell;

    if (hasThumbnail) {
      // Post thumbnail clipped to squircle with day number overlaid.
      cell = ClipSquircle(
        child: SizedBox(
          width: cellW,
          height: cellH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: dayData.thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (cellW * 2).toInt(),
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 100),
                placeholder: (context, url) =>
                    Container(color: Colors.white.withValues(alpha: 0.08)),
                errorWidget: (context, url, error) =>
                    Container(color: Colors.white.withValues(alpha: 0.08)),
              ),
              Center(child: dayText(MainColors.white)),
            ],
          ),
        ),
      );
    } else if (dayData.isFuture) {
      // Future days: empty, no cell rendered.
      cell = SizedBox(width: cellW, height: cellH);
    } else {
      // Current month, no post: lightweight dark squircle (avoids expensive
      // BackdropFilter that caused GPU memory pressure on iOS).
      cell = ClipPath(
        clipper: const SquircleClipper(),
        child: Container(
          width: cellW,
          height: cellH,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          child: Center(child: dayText(MainColors.dark)),
        ),
      );
    }

    return GestureDetector(
      onTap: dayData.isFuture ? null : () => onTap?.call(dayData.date),
      child: cell,
    );
  }
}
