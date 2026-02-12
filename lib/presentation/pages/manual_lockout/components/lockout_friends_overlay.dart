import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Full-screen friends overlay shown on long-press during lockout.
///
/// Gaussian blur + semi-transparent scrim over the lockout content.
/// Vertical list of locked-out friends, scrolling upward (newest first,
/// overflow goes off the top). Stays open until tap-outside or back.
class LockoutFriendsOverlay extends HookConsumerWidget {
  const LockoutFriendsOverlay({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  static const _pollInterval = Duration(minutes: 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = Theme.of(context).colorScheme.surface;
    // Text should contrast with lockout bg (which is the inverted surface)
    final textColor =
        surface.computeLuminance() < 0.5 ? MainColors.white : MainColors.dark;

    final cacheState = ref.watch(friendsLockedOutCacheProvider);
    final cacheNotifier = ref.read(friendsLockedOutCacheProvider.notifier);

    // Current user's session ID for same-lockout detection
    final storable = ref.read(manualLockoutStorableProvider);
    final currentSessionId = useState<String?>(null);

    useEffect(() {
      storable.getLockoutSessionId().then((id) {
        currentSessionId.value = id;
      });
      return null;
    }, [cacheState.activeLockouts.length]);

    // Refresh data when overlay opens
    useEffect(() {
      cacheNotifier.refresh();
      return null;
    }, const []);

    // Poll every minute while overlay is open
    useEffect(() {
      final timer = Timer.periodic(_pollInterval, (_) {
        cacheNotifier.refresh();
      });
      return timer.cancel;
    }, const []);

    // Refresh on app resume
    useEffect(() {
      final observer = _LifecycleObserver((state) {
        if (state == AppLifecycleState.resumed) {
          cacheNotifier.refresh();
        }
      });
      WidgetsBinding.instance.addObserver(observer);
      return () => WidgetsBinding.instance.removeObserver(observer);
    }, const []);

    // Remove expired lockouts periodically
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        cacheNotifier.removeExpiredLockouts();
      });
      return timer.cancel;
    }, const []);

    // Sort by lockout creation time, newest first
    final friends = [...cacheState.activeLockouts]
      ..sort((a, b) {
        final aTime = a.createdAt ?? a.startedAt;
        final bTime = b.createdAt ?? b.startedAt;
        return bTime.compareTo(aTime);
      });

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: AppGlassContainer(
        config: const GlassConfig(
          variant: GlassVariant.regular,
          cornerRadius: 0,
        ),
        child: SafeArea(
          child: _FriendsList(
            friends: friends,
            textColor: textColor,
            currentSessionId: currentSessionId.value,
          ),
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.friends,
    required this.textColor,
    required this.currentSessionId,
  });

  final List<LockoutSessionModel> friends;
  final Color textColor;
  final String? currentSessionId;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Text(
          'No friends locked out',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: textColor.withValues(alpha: 0.6),
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    // Reverse so list overflows upward (newest at bottom, scroll up to see more)
    return Align(
      alignment: Alignment.bottomCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final session = friends[index];
          final isInSameLockout =
              currentSessionId != null && session.id == currentSessionId;
          return _FriendOverlayItem(
            session: session,
            textColor: textColor,
            isInSameLockout: isInSameLockout,
          );
        },
      ),
    );
  }
}

class _FriendOverlayItem extends StatelessWidget {
  const _FriendOverlayItem({
    required this.session,
    required this.textColor,
    required this.isInSameLockout,
  });

  final LockoutSessionModel session;
  final Color textColor;
  final bool isInSameLockout;

  static const double _avatarSize = 39.0;

  @override
  Widget build(BuildContext context) {
    final timeRemaining = _formatTimeRemaining(session.endsAt);
    final hasActivity =
        session.actionText != null && session.actionText!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.username ?? '',
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 24,
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasActivity)
                  Text(
                    session.actionText!,
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeRemaining,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 24,
              color: textColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarWidget = session.avatarUrl != null &&
            session.avatarUrl!.isNotEmpty
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: session.avatarUrl!,
              width: _avatarSize,
              height: _avatarSize,
              fit: BoxFit.cover,
              placeholder: (_, __) => _fallbackAvatar(),
              errorWidget: (_, __, ___) => _fallbackAvatar(),
            ),
          )
        : _fallbackAvatar();

    if (!isInSameLockout) {
      return avatarWidget;
    }

    // Accent border for same-lockout friends
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MainColors.accent, width: 2),
      ),
      child: avatarWidget,
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MainColors.accent.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Text(
          (session.username ?? '?')[0].toUpperCase(),
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: MainColors.accent,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime endsAt) {
    final now = DateTime.now();
    final remaining = endsAt.difference(now);
    if (remaining.isNegative) {
      return '0:00';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver(this.onStateChange);

  final void Function(AppLifecycleState) onStateChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChange(state);
  }
}
