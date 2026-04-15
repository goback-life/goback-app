import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    required this.label,
    required this.value,
    required this.scale,
    super.key,
  });

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w700,
              fontSize: 18 * s,
              color: MainColors.accent,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            label,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 11 * s,
              color: MainColors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
