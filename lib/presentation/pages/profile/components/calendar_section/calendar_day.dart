import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/models/calendar_day_model.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class CalendarDay extends StatelessWidget with MainLayout, ProfileLayout {
  const CalendarDay({required this.dayData, this.onTap, super.key});

  final CalendarDayModel dayData;
  final void Function(DateTime)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Color textColor;
    Color borderColor;
    final hasThumbnail =
        dayData.thumbnailUrl != null && dayData.thumbnailUrl!.isNotEmpty;

    final bool useGlass =
        dayData.isCurrentMonth && !hasThumbnail && !dayData.isFuture;

    if (dayData.isFuture) {
      textColor = colorScheme.surface.withValues(alpha: 0.3);
      borderColor = colorScheme.surface.withValues(alpha: 0.3);
    } else if (dayData.isCurrentMonth) {
      textColor = hasThumbnail
          ? colorScheme.surface
          : colorScheme.primaryContainer;
      borderColor = Colors.transparent;
    } else {
      textColor = colorScheme.surface;
      borderColor = hasThumbnail ? Colors.transparent : colorScheme.surface;
    }

    final textWidget = Center(
      child: Text(
        dayData.day.toString(),
        style: textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    Widget cell;
    if (useGlass) {
      cell = Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalMarginBetweenDays),
        child: AppGlassContainer(
          config: GlassConfig(
            variant: GlassVariant.regular,
            cornerRadius: borderRadius,
          ),
          child: SizedBox(
            height: height,
            width: width,
            child: textWidget,
          ),
        ),
      );
    } else {
      cell = Container(
        height: height,
        width: width,
        margin: EdgeInsets.symmetric(horizontal: horizontalMarginBetweenDays),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 1.5),
          image: hasThumbnail
              ? DecorationImage(
                  image: CachedNetworkImageProvider(dayData.thumbnailUrl!),
                  fit: BoxFit.cover,
                  opacity: dayData.isCurrentMonth ? 1.0 : 0.5,
                )
              : null,
        ),
        child: textWidget,
      );
    }

    return GestureDetector(
      onTap: dayData.isFuture ? null : () => onTap?.call(dayData.date),
      child: cell,
    );
  }
}
