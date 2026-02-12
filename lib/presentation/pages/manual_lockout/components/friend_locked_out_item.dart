import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';

class FriendLockedOutItem extends StatelessWidget {
  const FriendLockedOutItem({
    super.key,
    required this.session,
    required this.onTap,
    this.isInSameLockout = false,
  });

  final LockoutSessionModel session;
  final VoidCallback onTap;
  final bool isInSameLockout;

  static const double _avatarSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final timeRemaining = _formatTimeRemaining(session.endsAt);
    final hasActivity = session.actionText != null && session.actionText!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: AppGlassContainer(
          config: GlassConfig(
            variant: GlassVariant.regular,
            cornerRadius: 12,
            tint: isInSameLockout ? MainColors.accent : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatar(colorScheme, textTheme),
                const SizedBox(height: 6),
                Text(
                  session.username ?? '',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.surface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  timeRemaining,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasActivity) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.actionText!,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.surface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, TextTheme textTheme) {
    if (session.avatarUrl != null && session.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: session.avatarUrl!,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildFallbackAvatar(colorScheme, textTheme),
          errorWidget: (_, __, ___) => _buildFallbackAvatar(colorScheme, textTheme),
        ),
      );
    }
    return _buildFallbackAvatar(colorScheme, textTheme);
  }

  Widget _buildFallbackAvatar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(color: colorScheme.primary, width: 1),
      ),
      child: Center(
        child: Text(
          (session.username ?? '?')[0].toUpperCase(),
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime endsAt) {
    final now = DateTime.now();
    final remaining = endsAt.difference(now);

    if (remaining.isNegative) return '0m';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
