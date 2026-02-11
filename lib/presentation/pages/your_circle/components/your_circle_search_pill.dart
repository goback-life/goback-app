import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class YourCircleSearchPill extends StatelessWidget
    with MainLayout, YourCircleLayout {
  const YourCircleSearchPill({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.controller,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: searchPillWidth,
      height: searchPillHeight,
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.clear,
          tint: MainColors.accent,
          cornerRadius: searchPillRadius,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              maxLength: 30,
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: MainColors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: MainColors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
