import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:flutter/material.dart';

class FriendLockedOutItem extends StatelessWidget {
  const FriendLockedOutItem({
    super.key,
    required this.session,
    required this.onTap,
  });

  final LockoutSessionModel session;
  final VoidCallback onTap;

  static const double _avatarSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final timeRemaining = _formatTimeRemaining(session.endsAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(colorScheme, textTheme),
            const SizedBox(height: 4),
            Text(
              session.username ?? '',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.surface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              timeRemaining,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.surface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
