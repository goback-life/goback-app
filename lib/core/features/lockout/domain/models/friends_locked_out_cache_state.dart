import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'friends_locked_out_cache_state.freezed.dart';

/// State model for the friends locked out cache.
/// Tracks cached lockout sessions and last fetch timestamp.
/// Uses 2-minute TTL since lockouts change slowly (median ~30min).
@freezed
sealed class FriendsLockedOutCacheState with _$FriendsLockedOutCacheState {
  const factory FriendsLockedOutCacheState({
    @Default([]) List<LockoutSessionModel> activeLockouts,
    DateTime? lastFetchedAt,
    @Default(false) bool isFetching,
  }) = _FriendsLockedOutCacheState;
}
