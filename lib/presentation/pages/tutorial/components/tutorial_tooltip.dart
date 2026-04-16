import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Instructional glass tooltip for the tutorial flow.
///
/// Positioned at bottom-center by default. When [onTap] is provided, shows
/// a visible "Tap to continue" prompt so the user knows to interact.
class TutorialTooltip extends StatelessWidget {
  const TutorialTooltip({
    super.key,
    required this.message,
    this.onTap,
    this.bottomOffset = 200,
    this.buttonLabel,
    this.textColor,
    this.secondaryButtonLabel,
    this.onSecondaryTap,
  });

  final String message;
  final VoidCallback? onTap;
  final double bottomOffset;

  /// Custom label for the action button. Defaults to "Tap to continue".
  final String? buttonLabel;

  /// Override text color. Defaults to [MainColors.white].
  final Color? textColor;

  /// Optional secondary button (rendered next to the primary button).
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryButtonLabel != null && onSecondaryTap != null;

    return Positioned(
      left: TutorialLayout.tooltipHPadding,
      right: TutorialLayout.tooltipHPadding,
      bottom: bottomOffset,
      child: GestureDetector(
        onTap: hasSecondary ? null : onTap,
        behavior: hasSecondary
            ? HitTestBehavior.translucent
            : HitTestBehavior.opaque,
        child: AppGlassContainer(
          config: const GlassConfig(
            cornerRadius: TutorialLayout.tooltipCornerRadius,
            tint: MainColors.accent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? MainColors.white,
                    decoration: TextDecoration.none,
                    height: 1.5,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 16),
                  if (hasSecondary)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: onSecondaryTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: MainColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              secondaryButtonLabel!,
                              style: const TextStyle(
                                fontFamily: MainFontFamilies.quicksand,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: MainColors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: MainColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              buttonLabel ?? 'Tap to continue',
                              style: const TextStyle(
                                fontFamily: MainFontFamilies.quicksand,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: MainColors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: MainColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        buttonLabel ?? 'Tap to continue',
                        style: const TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: MainColors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
