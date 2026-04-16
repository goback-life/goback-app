import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

class ProfileTabToggle extends StatelessWidget {
  const ProfileTabToggle({
    required this.selectedIndex,
    required this.onChanged,
    this.scale = 1.0,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      config: const GlassConfig(
        variant: GlassVariant.clear,
        tint: MainColors.accent,
        cornerRadius: 20,
      ),
      child: Padding(
        padding: EdgeInsets.all(3 * scale),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pill(
              label: 'Calendar',
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
              scale: scale,
            ),
            _Pill(
              label: 'Stats',
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
              scale: scale,
            ),
            _Pill(
              label: 'Hobbies',
              isSelected: selectedIndex == 2,
              onTap: () => onChanged(2),
              scale: scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: 15 * scale,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? MainColors.accent.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14 * scale,
            color: isSelected
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
