import 'package:cloudless/core/features/lockout/data/mappers/lockout_session_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/friends_locked_out_cache_state.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friends_locked_out_cache_provider.g.dart';

/// Cache provider for friends currently locked out with 2-minute TTL.
/// Lockouts change slowly (median ~30min), so short TTL is appropriate.
/// Invalidate on push notification of new lockout.
@Riverpod(keepAlive: true)
class FriendsLockedOutCache extends _$FriendsLockedOutCache {
  static const _cacheTtl = Duration(minutes: 2);
  final _mapper = LockoutSessionDtoToModelMapper();

  @override
  FriendsLockedOutCacheState build() => const FriendsLockedOutCacheState();

  /// Returns true if cache is valid (exists and within TTL).
  bool get isCacheValid =>
      state.lastFetchedAt != null &&
      DateTime.now().difference(state.lastFetchedAt!) < _cacheTtl;

  /// Returns cached lockouts if valid, otherwise returns empty list.
  List<LockoutSessionModel> getCachedLockouts() => state.activeLockouts;

  /// Returns cached lockouts if valid, otherwise fetches fresh data.
  Future<List<LockoutSessionModel>> getCachedOrFetch() async {
    if (isCacheValid) {
      return state.activeLockouts;
    }

    if (state.isFetching) {
      // Wait for ongoing fetch
      return state.activeLockouts;
    }

    state = state.copyWith(isFetching: true);

    try {
      final service = ref.read(lockoutSessionServiceProvider);
      final result = await service.getFriendsLockedOut();

      return result.fold(
        (dtos) {
          final models = _mapper.mapDtoList(dtos);
          state = FriendsLockedOutCacheState(
            activeLockouts: models,
            lastFetchedAt: DateTime.now(),
            isFetching: false,
          );
          return models;
        },
        (error) {
          state = state.copyWith(isFetching: false);
          return state.activeLockouts;
        },
      );
    } catch (e) {
      state = state.copyWith(isFetching: false);
      return state.activeLockouts;
    }
  }

  /// Force refresh the cache, bypassing TTL.
  /// Call on push notification of new lockout.
  Future<List<LockoutSessionModel>> refresh() async {
    // Invalidate cache to force fetch
    state = state.copyWith(lastFetchedAt: null, isFetching: true);

    try {
      final service = ref.read(lockoutSessionServiceProvider);
      final result = await service.getFriendsLockedOut();

      return result.fold(
        (dtos) {
          final models = _mapper.mapDtoList(dtos);
          state = FriendsLockedOutCacheState(
            activeLockouts: models,
            lastFetchedAt: DateTime.now(),
            isFetching: false,
          );
          return models;
        },
        (error) {
          state = state.copyWith(isFetching: false);
          return state.activeLockouts;
        },
      );
    } catch (e) {
      state = state.copyWith(isFetching: false);
      return state.activeLockouts;
    }
  }

  /// Invalidate cache. Call on push notification of friend starting lockout.
  void invalidateCache() {
    state = const FriendsLockedOutCacheState();
  }

  /// Remove lockouts that have ended from cache.
  void removeExpiredLockouts() {
    final now = DateTime.now();
    final activeLockouts = state.activeLockouts
        .where((lockout) => lockout.endsAt.isAfter(now))
        .toList();

    if (activeLockouts.length != state.activeLockouts.length) {
      state = state.copyWith(activeLockouts: activeLockouts);
    }
  }
}
