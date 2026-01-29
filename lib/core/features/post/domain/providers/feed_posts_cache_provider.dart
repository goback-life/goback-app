import 'package:cloudless/core/features/post/domain/models/feed_cache_state.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/get_feed_posts_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_posts_cache_provider.g.dart';

/// Cache provider for feed posts with 5-minute TTL.
/// Persists across navigation and provides instant feed access.
@Riverpod(keepAlive: true)
class FeedPostsCache extends _$FeedPostsCache {
  static const _cacheTtl = Duration(minutes: 5);
  String? _currentUserId;

  @override
  FeedCacheState build() => const FeedCacheState();

  /// Returns true if cache is valid (exists and within TTL).
  bool get isCacheValid =>
      state.lastFetchedAt != null &&
      DateTime.now().difference(state.lastFetchedAt!) < _cacheTtl &&
      _currentUserId != null;

  /// Returns cached posts if valid, otherwise returns empty list.
  /// Use getCachedOrFetch for automatic fetching when cache is invalid.
  List<FeedPostModel> getCachedPosts() => state.posts;

  /// Preloads all feed pages in background for the given user.
  /// Safe to call multiple times - returns early if already preloading.
  Future<void> preloadFeed(String userId) async {
    if (state.isPreloading) return;
    if (userId.isEmpty || userId.trim().isEmpty) return;

    // Clear cache if user changed
    if (_currentUserId != null && _currentUserId != userId) {
      invalidateCache();
    }
    _currentUserId = userId;

    state = state.copyWith(isPreloading: true);

    try {
      DateTime? cursor;
      final allPosts = <FeedPostModel>[];
      var hasMore = true;

      while (hasMore) {
        final result = await ref.read(
          getFeedPostsProvider(userId: userId, cursor: cursor).future,
        );

        result.fold(
          (response) {
            allPosts.addAll(response.posts);
            hasMore = response.hasNextPage;
            if (response.posts.isNotEmpty) {
              cursor = response.posts.last.createdAt;
            }
          },
          (error) => hasMore = false,
        );
      }

      state = FeedCacheState(
        posts: allPosts,
        lastFetchedAt: DateTime.now(),
        oldestPostTimestamp: allPosts.isNotEmpty ? allPosts.last.createdAt : null,
        hasNextPage: false,
        isPreloading: false,
      );
    } catch (e) {
      state = state.copyWith(isPreloading: false);
    }
  }

  /// Returns cached posts if valid, otherwise fetches first page.
  /// For full preloading, use preloadFeed instead.
  Future<List<FeedPostModel>> getCachedOrFetch(String userId) async {
    if (isCacheValid && _currentUserId == userId) {
      return state.posts;
    }

    // Clear cache if user changed
    if (_currentUserId != null && _currentUserId != userId) {
      invalidateCache();
    }
    _currentUserId = userId;

    final result = await ref.read(
      getFeedPostsProvider(userId: userId).future,
    );

    return result.fold(
      (response) {
        state = FeedCacheState(
          posts: response.posts,
          lastFetchedAt: DateTime.now(),
          oldestPostTimestamp:
              response.posts.isNotEmpty ? response.posts.last.createdAt : null,
          hasNextPage: response.hasNextPage,
          isPreloading: false,
        );
        return response.posts;
      },
      (error) => state.posts,
    );
  }

  /// Updates cache with new posts from a fetch operation.
  /// Used by useFeedPosts to sync cache with latest data.
  void updateCache(List<FeedPostModel> posts, {bool? hasNextPage}) {
    state = state.copyWith(
      posts: posts,
      lastFetchedAt: DateTime.now(),
      oldestPostTimestamp: posts.isNotEmpty ? posts.last.createdAt : null,
      hasNextPage: hasNextPage ?? state.hasNextPage,
    );
  }

  /// Adds a newly created post to the top of the cache.
  void addPost(FeedPostModel post) {
    // Check if post already exists
    if (state.posts.any((p) => p.id == post.id)) return;

    state = state.copyWith(
      posts: [post, ...state.posts],
    );
  }

  /// Updates an existing post in the cache.
  void updatePost(FeedPostModel post) {
    final index = state.posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final updatedPosts = List<FeedPostModel>.from(state.posts);
    updatedPosts[index] = post;
    state = state.copyWith(posts: updatedPosts);
  }

  /// Removes a post from the cache by ID.
  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }

  /// Removes posts older than 24 hours from the cache.
  /// Should be called periodically to keep cache clean.
  void removeExpiredPosts() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final validPosts = state.posts
        .where((p) => p.publishedAt.isAfter(cutoff))
        .toList();

    if (validPosts.length != state.posts.length) {
      state = state.copyWith(posts: validPosts);
    }
  }

  /// Clears all cached data. Call on logout.
  void invalidateCache() {
    _currentUserId = null;
    state = const FeedCacheState();
  }

  /// Gets the current cached user ID.
  String? get currentUserId => _currentUserId;
}
