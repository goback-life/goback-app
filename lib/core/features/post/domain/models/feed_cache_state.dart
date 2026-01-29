import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'feed_cache_state.freezed.dart';

/// State model for the feed posts cache.
/// Tracks cached posts, timestamps for pagination, and loading state.
@freezed
sealed class FeedCacheState with _$FeedCacheState {
  const factory FeedCacheState({
    @Default([]) List<FeedPostModel> posts,
    DateTime? lastFetchedAt,
    DateTime? oldestPostTimestamp,
    @Default(true) bool hasNextPage,
    @Default(false) bool isPreloading,
  }) = _FeedCacheState;
}
