import 'dart:io';

import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Branded card for sharing lockout completion to external platforms.
/// Sized at 360x450 logical (4:5 ratio → 1080x1350 at 3x).
///
/// When [imagePath] is provided, renders a post-preview layout with the image.
/// Otherwise falls back to the score-centric layout.
class LockoutShareCard extends StatelessWidget {
  const LockoutShareCard({
    required this.score,
    required this.durationMinutes,
    required this.username,
    this.activityText,
    this.imagePath,
    this.description,
    super.key,
  });

  final int? score;
  final int durationMinutes;
  final String username;
  final String? activityText;
  final String? imagePath;
  final String? description;

  String get _durationStr {
    final dH = durationMinutes ~/ 60;
    final dM = durationMinutes % 60;
    return dH > 0 ? '${dH}h ${dM}m' : '${dM}m';
  }

  @override
  Widget build(BuildContext context) {
    return imagePath != null ? _buildImageLayout() : _buildScoreLayout();
  }

  /// Post-preview layout: branding header, large image, description, footer.
  Widget _buildImageLayout() {
    return Container(
      width: 360,
      height: 450,
      decoration: BoxDecoration(
        color: MainColors.dark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'remember boredom?',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: MainColors.white.withValues(alpha: 0.6),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Assets.svg.logoApp.render(height: 14),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath!),
                  width: 312,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Score + duration row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (score != null) ...[
                  Text(
                    '$score',
                    style: TextStyle(
                      fontFamily: MainFontFamilies.lilitaOne,
                      fontSize: 22,
                      color: score! >= 75
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: MainColors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Text(
                  _durationStr,
                  style: const TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: MainColors.white,
                  ),
                ),
              ],
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: MainColors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (username.isNotEmpty) ...[
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: MainColors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Assets.svg.logoApp.render(height: 10),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Score-centric layout (no image available).
  Widget _buildScoreLayout() {
    return Container(
      width: 360,
      height: 450,
      decoration: BoxDecoration(
        color: MainColors.dark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Text(
            'remember boredom?',
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: MainColors.white.withValues(alpha: 0.6),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Assets.svg.logoApp.render(height: 16),
          const Spacer(flex: 2),
          Text(
            score != null ? '$score' : '—',
            style: const TextStyle(
              fontFamily: MainFontFamilies.lilitaOne,
              fontSize: 96,
              color: MainColors.accent,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'score / 100',
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: MainColors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _durationStr,
            style: const TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 28,
              color: MainColors.white,
            ),
          ),
          if (activityText != null && activityText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              activityText!,
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: MainColors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
          const Spacer(flex: 2),
          if (username.isNotEmpty)
            Text(
              '@$username',
              style: const TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: MainColors.white,
              ),
            ),
          const SizedBox(height: 8),
          Assets.svg.logoApp.render(height: 12),
          const Spacer(),
        ],
      ),
    );
  }
}
