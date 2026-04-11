import 'package:cloudless/core/utilities/date_formatter.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeDateBadge extends StatelessWidget with MainLayout, HomeLayout {
  const HomeDateBadge({this.displayDate, super.key});

  /// The date to display. If null, shows today's date.
  final DateTime? displayDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final locale = translator.currentLocale.toString();

    // Use displayDate if provided, otherwise use today
    final dateToShow = displayDate ?? DateTime.now();
    final formattedDate = DateFormatter.formatDayMonth(dateToShow, locale);

    return AppGlassContainer(
      config: GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: dateBadgeBorderRadius,
        tint: MainColors.accent,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dateBadgeHorizontalPadding,
          vertical: dateBadgeVerticalPadding,
        ),
        child: Text(
          formattedDate,
          style: textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primaryContainer,
          ),
        ),
      ),
    );
  }
}
