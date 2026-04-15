import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/features/share/data/services/share_card_capture_service.dart';
import 'package:cloudless/presentation/components/share_card/lockout_share_card.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a bottom dialog offering to share the lockout post to external socials.
/// Returns after the user taps share or dismiss.
class SharePostDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String lockoutId,
    required String authorId,
    String? imagePath,
    String? description,
    int participantCount = 0,
  }) async {
    // Fetch lockout session data (score, duration, activity)
    int? score;
    var durationMinutes = 0;
    String? activityText;
    var username = '';

    try {
      final response = await Supabase.instance.client
          .from('lockout_sessions')
          .select('goback_score, started_at, ends_at, action_text')
          .eq('id', lockoutId)
          .maybeSingle();

      if (response != null) {
        score = response['goback_score'] as int?;
        activityText = response['action_text'] as String?;
        final startedAt = DateTime.parse(response['started_at'] as String);
        final endsAt = DateTime.parse(response['ends_at'] as String);
        durationMinutes = endsAt.difference(startedAt).inMinutes;
      }
    } catch (_) {}

    try {
      final profileResult = await ref.read(getProfileProvider(authorId).future);
      profileResult.fold(
        (profile) => username = profile?.username ?? '',
        (_) {},
      );
    } catch (_) {}

    if (!context.mounted) return;

    final shouldShare = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: MainColors.dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MainColors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share post',
              style: TextStyle(
                fontFamily: MainFontFamilies.lilitaOne,
                fontSize: 28,
                color: MainColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              participantCount > 0
                  ? 'Locked out with $participantCount other${participantCount == 1 ? '' : 's'}'
                  : 'Share your lockout to socials',
              style: TextStyle(
                fontFamily: MainFontFamilies.quicksand,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: MainColors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MainColors.accent,
                  foregroundColor: MainColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Share to socials',
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(ctx).pop(false),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: MainColors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldShare == true && context.mounted) {
      await ShareCardCaptureService().captureAndShare(
        context,
        LockoutShareCard(
          score: score,
          durationMinutes: durationMinutes,
          username: username,
          activityText: activityText,
          imagePath: imagePath,
          description: description,
        ),
      );
    }
  }
}
