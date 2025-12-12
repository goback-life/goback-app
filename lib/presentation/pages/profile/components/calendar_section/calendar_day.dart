import 'package:cached_network_image/cached_network_image.dart';
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

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    final hasThumbnail =
        dayData.thumbnailUrl != null && dayData.thumbnailUrl!.isNotEmpty;

    if (dayData.isFuture) {
      backgroundColor = Colors.transparent;
      textColor = colorScheme.surface.withValues(alpha: 0.3);
      borderColor = colorScheme.surface.withValues(alpha: 0.3);
    } else if (dayData.isCurrentMonth) {
      backgroundColor = hasThumbnail ? Colors.transparent : colorScheme.surface;
      textColor = hasThumbnail
          ? colorScheme.surface
          : colorScheme.primaryContainer;
      borderColor = Colors.transparent;
    } else {
      backgroundColor = Colors.transparent;
      textColor = colorScheme.surface;
      borderColor = hasThumbnail ? Colors.transparent : colorScheme.surface;
    }

    return GestureDetector(
      onTap: dayData.isFuture ? null : () => onTap?.call(dayData.date),
      child: Container(
        height: height,
        width: width,
        margin: EdgeInsets.symmetric(horizontal: horizontalMarginBetweenDays),
        decoration: BoxDecoration(
          color: backgroundColor,
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
        child: Center(
          child: Text(
            dayData.day.toString(),
            style: textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
