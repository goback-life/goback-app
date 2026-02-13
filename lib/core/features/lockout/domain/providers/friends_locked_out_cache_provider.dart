import 'package:cloudless/core/features/lockout/data/mappers/lockout_session_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/lockout/data/providers/friends_locked_out_storable_provider.dart';
import 'package:cloudless/core/features/lockout/data/providers/lockout_session_service_provider.dart';
import 'package:cloudless/core/features/lockout/domain/models/friends_locked_out_cache_state.dart';
import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friends_locked_out_cache_provider.g.dart';

/// Cache provider for friends currently locked out.
///
/// Key design principles for seamless UX:
/// - Cache is persisted to storage to survive app restarts
/// - Data is NEVER cleared during refresh - only replaced when new data arrives
/// - Background fetches don't affect displayed data until complete
/// - On app restart, cached data shows immediately while fresh fetch happens
@Riverpod(keepAlive: true)
class FriendsLockedOutCache extends _$FriendsLockedOutCache {
  static const _cacheTtl = Duration(minutes: 1);
  static const _fetchTimeout = Duration(seconds: 30);
  final _mapper = LockoutSessionDtoToModelMapper();
  DateTime? _fetchStartedAt;

  @override
  FriendsLockedOutCacheState build() {
    // Load persisted cache on startup (defer to avoid modifying during build)
    Future.microtask(_loadFromStorage);
    return const FriendsLockedOutCacheState();
  }

  /// Load cached friends from persistent storage.
  Future<void> _loadFromStorage() async {
    try {
      final storable = ref.read(friendsLockedOutStorableProvider);
      final cached = await storable.getCachedFriends();

      if (cached.isNotEmpty) {
        final models = cached
            .map((json) => LockoutSessionModel.fromJson(json))
            .where((m) => m.endsAt.isAfter(DateTime.now())) // Filter expired
            .toList();

        if (models.isNotEmpty) {
          state = state.copyWith(activeLockouts: models);
        }
      }
    } catch (e) {
      logger.warning('[FriendsLockedOutCache] Error loading from storage: $e');
    }
  }

  /// Save current cache to persistent storage.
  Future<void> _saveToStorage(List<LockoutSessionModel> models) async {
    try {
      final storable = ref.read(friendsLockedOutStorableProvider);
      final jsonList = models.map((m) => m.toJson()).toList();
      await storable.setCachedFriends(jsonList);
    } catch (e) {
      logger.warning('[FriendsLockedOutCache] Error saving to storage: $e');
    }
  }

  /// Returns true if cache is valid (exists and within TTL).
  bool get isCacheValid =>
      state.lastFetchedAt != null &&
      DateTime.now().difference(state.lastFetchedAt!) < _cacheTtl;

  /// Returns current cached lockouts (never null, may be empty).
  List<LockoutSessionModel> get lockouts => state.activeLockouts;

  /// Returns true if a fetch is currently in progress.
  bool get isFetching => state.isFetching;

  /// Fetch friends locked out if cache is stale. Non-blocking.
  void ensureFresh() {
    // Reset stuck fetch flag after timeout
    final fetchStuck = state.isFetching &&
        _fetchStartedAt != null &&
        DateTime.now().difference(_fetchStartedAt!) > _fetchTimeout;
    if (fetchStuck) {
      state = state.copyWith(isFetching: false);
      _fetchStartedAt = null;
    }

    if (!isCacheValid && !state.isFetching) {
      _fetchInBackground();
    }
  }

  /// Force refresh, bypassing cache TTL. Non-blocking.
  void refresh() {
    // Reset stuck fetch flag after timeout
    final fetchStuck = state.isFetching &&
        _fetchStartedAt != null &&
        DateTime.now().difference(_fetchStartedAt!) > _fetchTimeout;
    if (fetchStuck) {
      state = state.copyWith(isFetching: false);
      _fetchStartedAt = null;
    }

    if (!state.isFetching) {
      _fetchInBackground();
    }
  }

  /// Fetch data in background without affecting current displayed data.
  Future<void> _fetchInBackground() async {
    _fetchStartedAt = DateTime.now();
    state = state.copyWith(isFetching: true);

    try {
      final service = ref.read(lockoutSessionServiceProvider);
      final result = await service.getFriendsLockedOut();

      result.fold(
        (dtos) {
          final models = _mapper.mapDtoList(dtos);

          // Update state atomically
          state = FriendsLockedOutCacheState(
            activeLockouts: models,
            lastFetchedAt: DateTime.now(),
            isFetching: false,
          );

          // Persist to storage for next app restart
          _saveToStorage(models);
        },
        (error) {
          logger.warning('[FriendsLockedOutCache] Fetch error: $error');
          state = state.copyWith(isFetching: false);
        },
      );
    } catch (e) {
      logger.error('[FriendsLockedOutCache] Exception: $e');
      state = state.copyWith(isFetching: false);
    }
  }

  /// Remove lockouts that have ended from cache.
  void removeExpiredLockouts() {
    final now = DateTime.now();
    final active = state.activeLockouts
        .where((lockout) => lockout.endsAt.isAfter(now))
        .toList();

    if (active.length != state.activeLockouts.length) {
      state = state.copyWith(activeLockouts: active);
      _saveToStorage(active);
    }
  }
}
