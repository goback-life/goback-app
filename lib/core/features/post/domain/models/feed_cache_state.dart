import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'feed_cache_state.freezed.dart';

/// State model for the feed posts cache.
/// Tracks cached posts, timestamps for pagination, and loading state.
/// Supports progressive background loading for seamless scrolling.
@freezed
sealed class FeedCacheState with _$FeedCacheState {
  const factory FeedCacheState({
    @Default([]) List<FeedPostModel> posts,
    DateTime? lastFetchedAt,
    DateTime? oldestPostTimestamp,
    DateTime? newestPostTimestamp,
    @Default(true) bool hasNextPage,
    @Default(false) bool isPreloading,

    /// Number of posts currently being loaded in background
    @Default(0) int backgroundLoadingCount,

    /// Whether initial load (first page) is complete
    @Default(false) bool initialLoadComplete,

    /// Whether all available posts have been loaded
    @Default(false) bool fullyLoaded,
  }) = _FeedCacheState;
}
