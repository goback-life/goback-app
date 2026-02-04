import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_friends_locked_out_provider.g.dart';

/// Provider that fetches the list of friends currently in lockout sessions.
///
/// Uses cache with 2-minute TTL (lockouts change slowly, median ~30min).
/// Returns a list of LockoutSessionModel with user profile data.
/// Auto-disposes when no longer watched.
@riverpod
class GetFriendsLockedOut extends _$GetFriendsLockedOut {
  @override
  Future<Result<List<LockoutSessionModel>>> build() async {
    final cacheNotifier = ref.watch(friendsLockedOutCacheProvider.notifier);

    try {
      final lockouts = await cacheNotifier.getCachedOrFetch();
      return Result.success(lockouts);
    } catch (e) {
      return Result.failure(
        e is Exception ? e : Exception('Failed to get friends locked out: $e'),
      );
    }
  }

  /// Force refresh the list of friends locked out, bypassing cache.
  /// Keeps showing old data during refresh to prevent UI flickering.
  Future<void> refresh() async {
    logger.info('[GetFriendsLockedOut] refresh() called');
    // Don't set AsyncLoading - keep showing old data during refresh
    final cacheNotifier = ref.read(friendsLockedOutCacheProvider.notifier);
    try {
      final lockouts = await cacheNotifier.refresh();
      logger.info('[GetFriendsLockedOut] Got ${lockouts.length} lockouts');
      state = AsyncData(Result.success(lockouts));
    } catch (e) {
      logger.error('[GetFriendsLockedOut] Error: $e');
      // On error, keep old data rather than showing error state
      // state = AsyncData(Result.failure(...));
    }
  }
}
