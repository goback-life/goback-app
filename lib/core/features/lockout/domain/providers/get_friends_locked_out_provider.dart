import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_friends_locked_out_provider.g.dart';

/// Provider that fetches the list of friends currently in lockout sessions.
///
/// Watches the cache state so it rebuilds when background fetches complete.
/// Returns a list of LockoutSessionModel with user profile data.
/// Auto-disposes when no longer watched.
@riverpod
class GetFriendsLockedOut extends _$GetFriendsLockedOut {
  @override
  Future<Result<List<LockoutSessionModel>>> build() async {
    // Watch cache state - rebuilds when background fetch completes
    final cacheState = ref.watch(friendsLockedOutCacheProvider);
    final cacheNotifier = ref.read(friendsLockedOutCacheProvider.notifier);

    // Trigger background fetch if cache is stale (deferred to avoid
    // modifying another provider's state during this provider's build)
    Future.microtask(cacheNotifier.ensureFresh);

    // ignore: avoid_print
    print('[GetFriendsLockedOut] build: returning ${cacheState.activeLockouts.length} lockouts from cache');
    for (final l in cacheState.activeLockouts) {
      // ignore: avoid_print
      print('[GetFriendsLockedOut]   lockout: id=${l.id}, user=${l.username}, endsAt=${l.endsAt}');
    }

    return Result.success(cacheState.activeLockouts);
  }

  /// Force refresh, keeps showing old data during fetch.
  void refresh() {
    logger.info('[GetFriendsLockedOut] refresh() called');
    final cacheNotifier = ref.read(friendsLockedOutCacheProvider.notifier);
    cacheNotifier.refresh();
    // Cache state update will trigger a rebuild of this provider automatically
  }
}
