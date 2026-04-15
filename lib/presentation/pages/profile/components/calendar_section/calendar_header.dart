import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Path data for the down-pointing arrow (viewBox 48x57.4862).
/// Reused from the add-friends menu glass arrows.
const _kArrowDownPathData = GlassPathData(
  viewBoxWidth: 48.0027,
  viewBoxHeight: 57.4862,
  commands: [
    ['M', 23.9598, 0],
    ['C', 27.1676, 0, 29.7683, 2.60079, 29.7684, 5.80859],
    ['L', 29.7684, 37.7227],
    ['L', 37.9158, 29.5752],
    ['C', 40.2233, 27.2678, 43.9648, 27.2678, 46.2723, 29.5752],
    ['C', 48.5796, 31.8826, 48.5796, 35.6233, 46.2723, 37.9307],
    ['L', 28.4451, 55.7568],
    ['C', 26.5491, 57.6525, 23.6863, 57.9892, 21.4451, 56.7695],
    ['C', 20.7592, 56.4814, 20.116, 56.0595, 19.5574, 55.501],
    ['L', 1.73029, 37.6748],
    ['C', -0.576758, 35.3675, -0.576771, 31.6267, 1.73029, 29.3193],
    ['C', 4.03779, 27.0119, 7.77923, 27.012, 10.0867, 29.3193],
    ['L', 18.1512, 37.3818],
    ['L', 18.1512, 5.80859],
    ['C', 18.1512, 2.6008, 20.752, 0.0000237074, 23.9598, 0],
    ['Z'],
  ],
);

class CalendarHeader extends StatelessWidget with MainLayout, ProfileLayout {
  const CalendarHeader({
    required this.selectedMonth,
    required this.onPreviousMonth,
    this.scale = 1.0,
    super.key,
    this.onNextMonth,
  });

  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // Format: "MMM 'YY" -> e.g. "Feb '26"
    final monthAbbr = DateFormat('MMM').format(selectedMonth);
    final yearShort = selectedMonth.year.toString().substring(2);
    final displayText = "$monthAbbr '$yearShort";

    final arrowW = arrowWidth * scale;
    final arrowH = arrowHeight * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlassArrow(
            arrowWidth: arrowW,
            arrowHeight: arrowH,
            isLeft: true,
            onTap: onPreviousMonth,
          ),
          const Spacer(),
          Text(
            displayText,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: monthFontSize * scale,
              letterSpacing: monthTracking * scale,
              color: MainColors.white,
            ),
          ),
          const Spacer(),
          _GlassArrow(
            arrowWidth: arrowW,
            arrowHeight: arrowH,
            isLeft: false,
            onTap: onNextMonth,
          ),
        ],
      ),
    );
  }
}

/// A glass-tinted arrow button for month navigation.
/// Uses the same arrow path data as the add-friends menu, rotated
/// 90 degrees via [RotatedBox] for left/right pointing.
class _GlassArrow extends StatelessWidget {
  const _GlassArrow({
    required this.arrowWidth,
    required this.arrowHeight,
    required this.isLeft,
    this.onTap,
  });

  final double arrowWidth;
  final double arrowHeight;
  final bool isLeft;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    // quarterTurns=1 rotates 90 CW (down->left), quarterTurns=3 (down->right)
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: SizedBox(
          width: arrowWidth < 44 ? 44 : arrowWidth,
          height: arrowHeight < 44 ? 44 : arrowHeight,
          child: Center(
            child: SizedBox(
              width: arrowWidth,
              height: arrowHeight,
              child: RotatedBox(
                quarterTurns: isLeft ? 1 : 3,
                child: const AppGlassContainer(
                  config: GlassConfig(
                    tint: MainColors.accent,
                    pathData: _kArrowDownPathData,
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
