import 'dart:async';

import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/friend_locked_out_item.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/join_lockout_dialog.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Displays friends currently in lockout sessions.
///
/// Design principles:
/// - Watches cache state directly for instant updates
/// - Never shows loading after initial load (seamless UX)
/// - Polls every minute for new friends
/// - Refreshes on app resume
/// - Data persists across minimize/maximize
class FriendsLockedOutList extends HookConsumerWidget {
  const FriendsLockedOutList({super.key});

  static const _pollInterval = Duration(minutes: 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Watch the cache state directly - this is the single source of truth
    final cacheState = ref.watch(friendsLockedOutCacheProvider);
    final cacheNotifier = ref.read(friendsLockedOutCacheProvider.notifier);

    // Track the current user's lockout session ID for same-lockout detection
    final storable = ref.read(manualLockoutStorableProvider);
    final currentSessionId = useState<String?>(null);

    // Fetch current session ID on mount and when cache updates
    useEffect(() {
      void fetchSessionId() {
        storable.getLockoutSessionId().then((id) {
          // ignore: avoid_print
          print('[SAME-LOCKOUT] Fetched currentSessionId: $id');
          currentSessionId.value = id;
        });
      }
      fetchSessionId();
      return null;
    }, [cacheState.activeLockouts.length]);

    // ignore: avoid_print
    print('[WIDGET] build: ${cacheState.activeLockouts.length} friends, isFetching=${cacheState.isFetching}, currentSessionId=${currentSessionId.value}');

    // Ensure data is fresh on first build (defer to after frame completes)
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cacheNotifier.ensureFresh();
      });
      return null;
    }, const []);

    // Poll for new friends every minute
    useEffect(() {
      final timer = Timer.periodic(_pollInterval, (_) {
        cacheNotifier.refresh();
      });
      return timer.cancel;
    }, const []);

    // Refresh on app resume
    useEffect(() {
      final observer = _LifecycleObserver((lifecycleState) {
        // ignore: avoid_print
        print('[WIDGET] Lifecycle: $lifecycleState');
        if (lifecycleState == AppLifecycleState.resumed) {
          // ignore: avoid_print
          print('[WIDGET] App resumed - calling refresh()');
          cacheNotifier.refresh();
        }
      });
      WidgetsBinding.instance.addObserver(observer);
      return () => WidgetsBinding.instance.removeObserver(observer);
    }, const []);

    // Remove expired lockouts periodically (every 30s)
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        cacheNotifier.removeExpiredLockouts();
      });
      return timer.cancel;
    }, const []);

    final friends = cacheState.activeLockouts;

    // Only show loading spinner on initial load (no data yet)
    if (friends.isEmpty && cacheState.isFetching) {
      return _buildLoading(colorScheme);
    }

    // Show empty state if no friends locked out
    if (friends.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    // Show the list of friends
    return _buildList(
      context,
      ref,
      friends,
      colorScheme,
      textTheme,
      currentSessionId.value,
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        translator.translate('pages.manual_lockout.friends_locked_out.empty'),
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.surface.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoading(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.surface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<LockoutSessionModel> friends,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String? currentSessionId,
  ) {
    // ignore: avoid_print
    print('[SAME-LOCKOUT] _buildList: currentSessionId=$currentSessionId');
    for (final f in friends) {
      final matches = currentSessionId != null && f.id == currentSessionId;
      // ignore: avoid_print
      print('[SAME-LOCKOUT]   -> ${f.username}: id=${f.id}, matches=$matches');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            translator.translate('pages.manual_lockout.friends_locked_out.title'),
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.surface.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final session = friends[index];
              final isInSameLockout =
                  currentSessionId != null && session.id == currentSessionId;
              // ignore: avoid_print
              print('[SAME-LOCKOUT] Friend ${session.username}: '
                  'session.id=${session.id}, '
                  'currentSessionId=$currentSessionId, '
                  'match=$isInSameLockout');
              return FriendLockedOutItem(
                session: session,
                onTap: () => _handleJoinTap(context, ref, session),
                isInSameLockout: isInSameLockout,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleJoinTap(
    BuildContext context,
    WidgetRef ref,
    LockoutSessionModel session,
  ) async {
    // Check if user is already locked out before showing dialog
    final lockoutState = ref.read(manualLockoutNotifierProvider);
    final isAlreadyLockedOut = lockoutState.whenOrNull(
          data: (state) => state.isLockedOut,
        ) ??
        false;

    if (isAlreadyLockedOut) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translator.translate('pages.home.lockout_join_error_already_locked'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final shouldJoin = await JoinLockoutDialog.show(context, session);
    if (shouldJoin != true || !context.mounted) return;

    try {
      final notifier = ref.read(manualLockoutNotifierProvider.notifier);
      await notifier.joinLockout(session.id);
    } catch (e) {
      logger.error('Error joining lockout', exception: e);
      if (context.mounted) {
        // Check for "already locked out" error from RPC
        final errorMessage = e.toString().contains('already in an active lockout')
            ? translator.translate('pages.home.lockout_join_error_already_locked')
            : translator.translate('pages.manual_lockout.friends_locked_out.error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
