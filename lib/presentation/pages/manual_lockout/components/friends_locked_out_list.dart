import 'dart:async';

import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/manual_lockout_storable_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:cloudless/core/features/lockout/domain/providers/manual_lockout_notifier_provider.dart';
import 'package:cloudless/core/features/lockout/domain/utilities/participant_distance.dart';
import 'package:cloudless/core/features/nfc/data/providers/nfc_service_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_snackbar.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/pages/home/components/dnd_prompt_dialog.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/friend_locked_out_item.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/join_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/manual_lockout/components/lockout_lifecycle_observer.dart';
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

    // Get user's friend IDs for distance computation
    final membersAsync = ref.watch(getCircleMembersProvider);
    final myFriendIds = useMemoized(() {
      return membersAsync.maybeWhen(
        data: (result) => result.fold(
          (members) => members.map((m) => m.profile.id).toSet(),
          (_) => <String>{},
        ),
        orElse: () => <String>{},
      );
    }, [membersAsync]);

    // Track the current user's lockout session ID for same-lockout detection
    final storable = ref.read(manualLockoutStorableProvider);
    final currentSessionId = useState<String?>(null);

    // Fetch current session ID on mount and when cache updates
    useEffect(() {
      void fetchSessionId() {
        storable.getLockoutSessionId().then((id) {
          currentSessionId.value = id;
        });
      }

      fetchSessionId();
      return null;
    }, [cacheState.activeLockouts.length]);

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
      final observer = LockoutLifecycleObserver((lifecycleState) {
        if (lifecycleState == AppLifecycleState.resumed) {
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
      myFriendIds,
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        translator.translate('pages.manual_lockout.friends_locked_out.empty'),
        style: textTheme.bodyMedium?.copyWith(
          color: MainColors.white.withValues(alpha: 0.6),
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
            color: MainColors.white.withValues(alpha: 0.6),
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
    Set<String> myFriendIds,
  ) {
    // Build a map of userId -> username from the friends list for joined_via
    // lookup
    final usernameById = <String, String>{};
    for (final session in friends) {
      usernameById[session.userId] = session.username ?? '';
    }

    // Compute distances and separate into tiers
    final d1d2Items = <_FriendWithDistance>[];
    var d3Count = 0;

    for (final session in friends) {
      final distance = ParticipantDistance.compute(
        participantId: session.userId,
        joinedVia: session.joinedVia,
        myFriendIds: myFriendIds,
      );

      if (distance >= 3) {
        d3Count++;
        continue;
      }

      // Look up the joined_via username
      String? joinedViaUsername;
      if (distance == 2 && session.joinedVia != null) {
        joinedViaUsername = usernameById[session.joinedVia!];
      }

      d1d2Items.add(
        _FriendWithDistance(
          session: session,
          distance: distance,
          joinedViaUsername: joinedViaUsername,
        ),
      );
    }

    // Sort: distance 1 first, then distance 2
    d1d2Items.sort((a, b) => a.distance.compareTo(b.distance));

    final itemCount = d1d2Items.length + (d3Count > 0 ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            translator.translate(
              'pages.manual_lockout.friends_locked_out.title',
            ),
            style: textTheme.titleSmall?.copyWith(
              color: MainColors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              // Last item is the "and N others" placeholder for distance 3+
              if (index >= d1d2Items.length) {
                return _buildOthersItem(d3Count, colorScheme, textTheme);
              }

              final item = d1d2Items[index];
              final isInSameLockout =
                  currentSessionId != null &&
                  item.session.id == currentSessionId;
              return FriendLockedOutItem(
                session: item.session,
                onTap: () => _handleJoinTap(context, ref, item.session),
                isInSameLockout: isInSameLockout,
                distance: item.distance,
                joinedViaUsername: item.joinedViaUsername,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOthersItem(
    int count,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SizedBox(
      width: 90,
      child: Center(
        child: Text(
          'and $count ${count == 1 ? 'other' : 'others'}',
          style: textTheme.labelSmall?.copyWith(
            color: MainColors.white.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _handleJoinTap(
    BuildContext context,
    WidgetRef ref,
    LockoutSessionModel session,
  ) async {
    // Check if user is already locked out before showing dialog
    final lockoutState = ref.read(manualLockoutNotifierProvider);
    final isAlreadyLockedOut =
        lockoutState.whenOrNull(data: (state) => state.isLockedOut) ?? false;

    if (isAlreadyLockedOut) {
      if (context.mounted) {
        MainSnackbar.showError(
          context,
          translator.translate('pages.home.lockout_join_error_already_locked'),
        );
      }
      return;
    }

    final shouldJoin = await JoinLockoutDialog.show(context, session);
    if (shouldJoin != true || !context.mounted) return;

    // Venue lockouts require NFC scan to verify same venue
    if (session.isOpenEnded && session.venueTagId != null) {
      await _handleVenueJoinWithNfc(context, ref, session);
      return;
    }

    // Timed lockouts: direct join (no NFC required)
    await _performJoin(context, ref, session);
  }

  /// Initiates NFC scan and joins venue lockout if tag matches.
  Future<void> _handleVenueJoinWithNfc(
    BuildContext context,
    WidgetRef ref,
    LockoutSessionModel session,
  ) async {
    final nfcService = ref.read(nfcServiceProvider);

    await nfcService.startReadSession(
      onTagRead: (venue) async {
        if (!context.mounted) return;

        if (venue.venueId != session.venueTagId) {
          MainSnackbar.showError(
            context,
            'You need to be at the same venue to join this lockout',
          );
          return;
        }

        // Tag matches — proceed with join
        await _performJoin(context, ref, session);
      },
      onInvalidTag: () {
        if (context.mounted) {
          MainSnackbar.showError(context, 'This is not a valid GoBack tag');
        }
      },
      onError: () {
        if (context.mounted) {
          MainSnackbar.showError(context, 'NFC scan failed. Please try again.');
        }
      },
    );
  }

  /// Performs the actual lockout join (DnD prompt + RPC call).
  Future<void> _performJoin(
    BuildContext context,
    WidgetRef ref,
    LockoutSessionModel session,
  ) async {
    try {
      await DndPromptDialog.showIfNeeded(context);
    } catch (_) {
      // DnD prompt is non-critical; proceed with join
    }
    if (!context.mounted) return;

    try {
      final notifier = ref.read(manualLockoutNotifierProvider.notifier);
      await notifier.joinLockout(session.id);
    } catch (e) {
      logger.error('Error joining lockout', exception: e);
      if (context.mounted) {
        // Check for "already locked out" error from RPC
        final errorMessage =
            e.toString().contains('already in an active lockout')
            ? translator.translate(
                'pages.home.lockout_join_error_already_locked',
              )
            : translator.translate(
                'pages.manual_lockout.friends_locked_out.error',
              );

        MainSnackbar.showError(context, errorMessage);
      }
    }
  }
}

class _FriendWithDistance {
  const _FriendWithDistance({
    required this.session,
    required this.distance,
    this.joinedViaUsername,
  });

  final LockoutSessionModel session;
  final int distance;
  final String? joinedViaUsername;
}
