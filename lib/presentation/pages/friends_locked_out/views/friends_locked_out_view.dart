import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/nfc/data/providers/nfc_service_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/lockout_lifecycle_observer.dart';
import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_routable.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Friends locked out view — matches the structure of [LockoutFriendsOverlay].
/// Uses the same cache provider, item layout, polling and lifecycle refresh.
class FriendsLockedOutView extends HookConsumerWidget {
  const FriendsLockedOutView({super.key});

  static const _pollInterval = Duration(minutes: 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheState = ref.watch(friendsLockedOutCacheProvider);
    final cacheNotifier = ref.read(friendsLockedOutCacheProvider.notifier);

    // Refresh on open (deferred to avoid modifying provider during build).
    useEffect(() {
      Future.microtask(() => cacheNotifier.refresh());
      return null;
    }, const []);

    // Poll every minute.
    useEffect(() {
      final timer = Timer.periodic(_pollInterval, (_) {
        cacheNotifier.refresh();
      });
      return timer.cancel;
    }, const []);

    // Refresh on app resume.
    useEffect(() {
      final observer = LockoutLifecycleObserver((state) {
        if (state == AppLifecycleState.resumed) {
          cacheNotifier.refresh();
        }
      });
      WidgetsBinding.instance.addObserver(observer);
      return () => WidgetsBinding.instance.removeObserver(observer);
    }, const []);

    // Remove expired lockouts periodically.
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        cacheNotifier.removeExpiredLockouts();
      });
      return timer.cancel;
    }, const []);

    // Sort newest first.
    final friends = [...cacheState.activeLockouts]
      ..sort((a, b) {
        final aTime = a.createdAt ?? a.startedAt;
        final bTime = b.createdAt ?? b.startedAt;
        return bTime.compareTo(aTime);
      });

    if (friends.isEmpty) {
      return Center(
        child: Text(
          'No friends locked out',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: MainColors.dark.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 64,
        ),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final session = friends[index];
          return _FriendItem(session: session);
        },
      ),
    );
  }
}

class _FriendItem extends HookConsumerWidget with MainLayout {
  const _FriendItem({required this.session});

  final LockoutSessionModel session;

  static const double _avatarSize = 39.0;
  static const int _minJoinableMinutes = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeDisplay = _formatTimeDisplay(session);
    final hasActivity =
        session.actionText != null && session.actionText!.isNotEmpty;
    final minutesRemaining = session.endsAt
        .difference(DateTime.now())
        .inMinutes;
    // Venue (open-ended) lockouts are always joinable; timed need 30+ min left
    final isJoinable =
        session.isOpenEnded || minutesRemaining > _minJoinableMinutes;
    final isJoining = useState(false);

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
                  style: const TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 24,
                    color: MainColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasActivity)
                  Text(
                    session.actionText!,
                    style: const TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                      color: MainColors.dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeDisplay,
            style: const TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontWeight: FontWeight.w500,
              fontSize: 24,
              color: MainColors.dark,
            ),
          ),
          if (isJoinable) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isJoining.value
                  ? null
                  : () => _handleJoin(context, ref, isJoining),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MainColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isJoining.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MainColors.white,
                        ),
                      )
                    : const Text(
                        'Join',
                        style: TextStyle(
                          fontFamily: MainFontFamilies.quicksand,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: MainColors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleJoin(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isJoining,
  ) async {
    // Venue (open-ended) lockouts require NFC scan to prove same venue
    if (session.isOpenEnded) {
      final nfcService = ref.read(nfcServiceProvider);
      await nfcService.startReadSession(
        onTagRead: (venue) async {
          if (!context.mounted) return;

          // Verify scanned venue matches the friend's venue
          if (session.venueTagId != null &&
              venue.venueId != session.venueTagId) {
            MainSnackbar.showError(
              context,
              'You need to be at the same venue to join this lockout',
            );
            return;
          }

          // Start independent venue lockout at scanned venue
          isJoining.value = true;
          try {
            await ref
                .read(manualLockoutNotifierProvider.notifier)
                .startVenueLockout(venue);
            if (context.mounted) {
              router.go(const ManualLockoutRoutable());
            }
          } catch (e) {
            if (!context.mounted) return;
            final message = e.toString().contains('already')
                ? 'Already in an active lockout'
                : 'Failed to join lockout';
            MainSnackbar.showError(context, message);
          } finally {
            if (context.mounted) isJoining.value = false;
          }
        },
        onInvalidTag: () {
          if (context.mounted) {
            MainSnackbar.showError(context, 'This is not a valid GoBack tag');
          }
        },
        onError: () {
          if (context.mounted) {
            MainSnackbar.showError(
              context,
              'NFC scan failed. Please try again.',
            );
          }
        },
      );
      return;
    }

    // Timed lockouts: direct join (no NFC required)
    isJoining.value = true;
    try {
      await ref
          .read(manualLockoutNotifierProvider.notifier)
          .joinLockout(session.id);
      if (context.mounted) {
        router.go(const ManualLockoutRoutable());
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString().contains('already')
          ? 'Already in an active lockout'
          : 'Failed to join lockout';
      MainSnackbar.showError(context, message);
    } finally {
      if (context.mounted) isJoining.value = false;
    }
  }

  Widget _buildAvatar() {
    if (session.avatarUrl != null && session.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: session.avatarUrl!,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallbackAvatar(),
          errorWidget: (_, __, ___) => _fallbackAvatar(),
        ),
      );
    }
    return _fallbackAvatar();
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
          style: const TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: MainColors.accent,
          ),
        ),
      ),
    );
  }

  String _formatTimeDisplay(LockoutSessionModel session) {
    if (session.isOpenEnded) {
      // Count up: elapsed time since lockout started
      final elapsed = DateTime.now().difference(session.startedAt);
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
    // Count down: time remaining until lockout ends
    final remaining = session.endsAt.difference(DateTime.now());
    if (remaining.isNegative) return '0:00';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}
