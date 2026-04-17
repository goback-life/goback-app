import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_member_model.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class FeedOnboardingPrompt extends StatelessWidget {
  const FeedOnboardingPrompt({required this.friends, super.key});

  final List<ConnectionMemberModel> friends;

  static const int _targetFriendCount = 4;

  @override
  Widget build(BuildContext context) {
    final friendCount = friends.length;
    final remaining = (_targetFriendCount - friendCount).clamp(
      0,
      _targetFriendCount,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final messageKey = remaining == 1
        ? 'pages.home.onboarding_prompt.message_one'
        : 'pages.home.onboarding_prompt.message';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGlassContainer(
          config: const GlassConfig(cornerRadius: 12, tint: MainColors.accent),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translator.translate(
                          'pages.home.onboarding_prompt.header',
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        translator.translate(
                          messageKey,
                          arguments: {'count': '$remaining'},
                        ),
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ProgressRing(current: friendCount, total: _targetFriendCount),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final friend in friends)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _FriendAvatar(
                  avatarUrl: friend.profile.avatarUrl,
                  username: friend.profile.username,
                ),
              ),
            for (var i = 0; i < remaining; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _DashedCircleButton(
                  onTap: () => router.push(const YourCircleRoutable()),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.avatarUrl, required this.username});

  final String? avatarUrl;
  final String username;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          memCacheWidth: (_size * 2).toInt(),
          memCacheHeight: (_size * 2).toInt(),
          placeholder: (_, __) => _fallback(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: MainColors.accent,
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: _size * 0.4,
            color: MainColors.dark,
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    final theme = Theme.of(context);

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(48, 48),
            painter: _ProgressRingPainter(
              progress: progress,
              trackColor: MainColors.dark.withValues(alpha: 0.08),
              progressColor: MainColors.accent,
            ),
          ),
          Text(
            '$current',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    const strokeWidth = 3.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DashedCircleButton extends StatelessWidget {
  const _DashedCircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: CustomPaint(
          painter: _DashedCirclePainter(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              size: 26,
              color: colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 3) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashCount = 20;
    const gapAngle = pi / 48;
    const dashAngle = (2 * pi / dashCount) - gapAngle;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle) - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
