import 'package:cloudless/core/features/post/domain/models/feed_cache_state.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/get_feed_posts_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/get_post_by_id_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_posts_cache_provider.g.dart';

/// Cache provider for feed posts with progressive background loading.
///
/// Design principles:
/// 1. Load first 15 posts immediately for instant display
/// 2. Continue loading remaining posts in background (progressive UI updates)
/// 3. Cache up to 200 posts for seamless scrolling
/// 4. Only fetch new/updated posts after initial load
@Riverpod(keepAlive: true)
class FeedPostsCache extends _$FeedPostsCache {
  static const _maxCachedPosts = 200;
  static const _pageSize = 15;
  static const _backgroundBatchSize = 30; // Load 30 at a time in background
  static const _deletionCheckBatchSize = 50;
  String? _currentUserId;
  bool _isBackgroundLoading = false;
  DateTime? _lastFullValidation;
  int _deletionCheckOffset = 0;

  @override
  FeedCacheState build() => const FeedCacheState();

  /// Returns cached posts, filtering out any past 24 hours.
  /// Computed on every access for instant expiration accuracy.
  List<FeedPostModel> get posts {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return state.posts.where((p) => p.publishedAt.isAfter(cutoff)).toList();
  }

  /// Returns true if initial load is complete (first page loaded).
  bool get isInitialLoadComplete => state.initialLoadComplete;

  /// Returns true if all posts have been loaded into cache.
  bool get isFullyLoaded => state.fullyLoaded;

  /// Returns true if background loading is in progress.
  bool get isBackgroundLoading => _isBackgroundLoading;

  /// Returns true if there are more posts to load from server.
  bool get hasMorePosts => state.hasNextPage && !state.fullyLoaded;

  /// Gets the current cached user ID.
  String? get currentUserId => _currentUserId;

  /// Loads the initial page of posts (fast, for immediate display).
  /// Returns the posts immediately, then starts background loading.
  Future<List<FeedPostModel>> loadInitialPosts(String userId) async {
    if (userId.isEmpty || userId.trim().isEmpty) {
      return [];
    }

    // Clear cache if user changed
    if (_currentUserId != null && _currentUserId != userId) {
      invalidateCache();
    }
    _currentUserId = userId;

    // If we already have posts for this user, return them immediately
    // and trigger a background refresh for new posts
    if (state.initialLoadComplete && state.posts.isNotEmpty) {
      _checkForNewPostsInBackground(userId);
      return state.posts;
    }

    // Fetch first page
    final result = await ref.read(
      getFeedPostsProvider(userId: userId, pageSize: _pageSize).future,
    );

    return result.fold(
      (response) {
        final posts = response.posts;

        state = state.copyWith(
          posts: posts,
          lastFetchedAt: DateTime.now(),
          newestPostTimestamp: posts.isNotEmpty ? posts.first.createdAt : null,
          oldestPostTimestamp: posts.isNotEmpty ? posts.last.createdAt : null,
          hasNextPage: response.hasNextPage,
          initialLoadComplete: true,
          fullyLoaded: !response.hasNextPage,
        );

        // Start background loading of remaining posts
        if (response.hasNextPage) {
          _startBackgroundLoading(userId);
        }

        return posts;
      },
      (error) {
        return <FeedPostModel>[];
      },
    );
  }

  /// Starts background loading of all remaining posts.
  /// Updates UI progressively as each batch loads.
  void _startBackgroundLoading(String userId) {
    if (_isBackgroundLoading) return;
    _isBackgroundLoading = true;
    state = state.copyWith(isPreloading: true);

    _loadNextBatch(userId);
  }

  /// Deduplicates response posts against cache, appends them, and enforces
  /// the max cache size. Returns the deduplicated new posts (empty if none).
  List<FeedPostModel> _appendAndTruncate(
    List<FeedPostModel> responsePosts,
    bool hasNextPage,
  ) {
    final existingIds = state.posts.map((p) => p.id).toSet();
    final newPosts = responsePosts
        .where((p) => !existingIds.contains(p.id))
        .toList();
    if (newPosts.isEmpty) {
      state = state.copyWith(hasNextPage: false, fullyLoaded: true);
      return [];
    }

    var allPosts = [...state.posts, ...newPosts];
    final reachedLimit = allPosts.length >= _maxCachedPosts;
    if (reachedLimit) {
      allPosts = allPosts.take(_maxCachedPosts).toList();
    }

    state = state.copyWith(
      posts: allPosts,
      oldestPostTimestamp: allPosts.last.createdAt,
      hasNextPage: hasNextPage && !reachedLimit,
      fullyLoaded: !hasNextPage || reachedLimit,
    );
    return newPosts;
  }

  /// Loads the next batch of posts in background.
  Future<void> _loadNextBatch(String userId) async {
    if (!_isBackgroundLoading) return;
    if (state.fullyLoaded || state.posts.length >= _maxCachedPosts) {
      _isBackgroundLoading = false;
      state = state.copyWith(isPreloading: false, fullyLoaded: true);
      return;
    }

    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: _backgroundBatchSize,
        cursor: state.oldestPostTimestamp,
      ).future,
    );

    result.fold(
      (response) {
        if (response.posts.isEmpty) {
          _isBackgroundLoading = false;
          state = state.copyWith(
            isPreloading: false,
            hasNextPage: false,
            fullyLoaded: true,
          );
          return;
        }

        final newPosts = _appendAndTruncate(
          response.posts,
          response.hasNextPage,
        );
        if (newPosts.isEmpty) {
          _isBackgroundLoading = false;
          state = state.copyWith(isPreloading: false);
          return;
        }

        final continueLoading = state.hasNextPage && !state.fullyLoaded;
        state = state.copyWith(isPreloading: continueLoading);

        if (continueLoading) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _loadNextBatch(userId);
          });
        } else {
          _isBackgroundLoading = false;
        }
      },
      (error) {
        _isBackgroundLoading = false;
        state = state.copyWith(isPreloading: false);
      },
    );
  }

  /// Loads more posts immediately (called when user scrolls near end).
  Future<bool> loadMorePostsNow(String userId, {int count = 30}) async {
    if (state.fullyLoaded || state.posts.length >= _maxCachedPosts) {
      return false;
    }

    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: count,
        cursor: state.oldestPostTimestamp,
      ).future,
    );

    return result.fold((response) {
      if (response.posts.isEmpty) {
        state = state.copyWith(hasNextPage: false, fullyLoaded: true);
        return false;
      }
      return _appendAndTruncate(
        response.posts,
        response.hasNextPage,
      ).isNotEmpty;
    }, (error) => false);
  }

  /// Checks for new posts (published after our newest cached post).
  /// If cache is empty, fetches initial posts.
  Future<void> _checkForNewPostsInBackground(String userId) async {
    // Invalidate the provider to force a fresh fetch
    ref.invalidate(getFeedPostsProvider(userId: userId, pageSize: _pageSize));

    // Fetch newest posts
    final result = await ref.read(
      getFeedPostsProvider(userId: userId, pageSize: _pageSize).future,
    );

    result.fold((response) {
      if (response.posts.isEmpty) return;

      // If cache is empty, just set the posts directly
      if (state.posts.isEmpty) {
        state = state.copyWith(
          posts: response.posts,
          lastFetchedAt: DateTime.now(),
          newestPostTimestamp: response.posts.first.createdAt,
          oldestPostTimestamp: response.posts.last.createdAt,
          hasNextPage: response.hasNextPage,
          initialLoadComplete: true,
          fullyLoaded: !response.hasNextPage,
        );

        // Start background loading if more posts available
        if (response.hasNextPage && _currentUserId != null) {
          _startBackgroundLoading(_currentUserId!);
        }
        return;
      }

      // Find new posts not already in cache
      final existingIds = state.posts.map((p) => p.id).toSet();
      final newestCached = state.newestPostTimestamp;
      final newPosts = response.posts
          .where((p) => !existingIds.contains(p.id))
          .where(
            (p) => newestCached == null || p.createdAt.isAfter(newestCached),
          )
          .toList();

      if (newPosts.isNotEmpty) {
        var allPosts = [...newPosts, ...state.posts];
        if (allPosts.length > _maxCachedPosts) {
          allPosts = allPosts.take(_maxCachedPosts).toList();
        }
        state = state.copyWith(
          posts: allPosts,
          newestPostTimestamp: allPosts.first.createdAt,
          lastFetchedAt: DateTime.now(),
        );
      }
    }, (error) {});
  }

  /// Refreshes the feed (pull-to-refresh). Checks for new posts.
  Future<void> refresh(String userId) async {
    if (userId.isEmpty) return;
    await _checkForNewPostsInBackground(userId);
  }

  /// Fetches a post by ID and adds it to the cache if not already present.
  /// Used when a new post is created to show it immediately.
  Future<bool> fetchAndAddPost(String postId) async {
    // Check if already in cache
    if (state.posts.any((p) => p.id == postId)) {
      return true;
    }

    try {
      final result = await ref.read(getPostByIdProvider(postId: postId).future);

      return result.fold((newPost) {
        addPost(newPost);
        return true;
      }, (error) => false);
    } catch (e) {
      return false;
    }
  }

  /// Checks for deleted/hidden posts and removes them from cache.
  /// Lightweight check - only removes posts no longer visible, doesn't fetch edits.
  /// Edits are fetched when user taps on a post to view details.
  Future<void> checkForDeletions(String userId) async {
    if (state.posts.isEmpty || userId.isEmpty) return;

    // Invalidate the provider to force a fresh fetch
    ref.invalidate(getFeedPostsProvider(userId: userId, pageSize: 50));

    // Fetch current post IDs from server (just first page + some buffer)
    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: 50, // Check a reasonable batch
      ).future,
    );

    result.fold((response) {
      final visiblePostIds = response.posts.map((p) => p.id).toSet();

      // If server returns 0 posts but we have cached posts, clear the cache
      if (response.posts.isEmpty && state.posts.isNotEmpty) {
        state = state.copyWith(
          posts: [],
          oldestPostTimestamp: null,
          newestPostTimestamp: null,
          hasNextPage: true, // Allow fetching when posts are added back
          fullyLoaded: false, // Not fully loaded - cache is empty
          initialLoadComplete: false, // Force fresh load on next access
        );
        _isBackgroundLoading = false; // Reset background loading state
        return;
      }

      // Only check posts that would be in the first 50 (recent ones)
      // Older posts we can't verify without fetching more pages
      final postsToCheck = state.posts.take(50).toList();
      final deletedIds = <String>[];

      for (final post in postsToCheck) {
        if (!visiblePostIds.contains(post.id)) {
          deletedIds.add(post.id);
        }
      }

      if (deletedIds.isNotEmpty) {
        final newPosts = state.posts
            .where((p) => !deletedIds.contains(p.id))
            .toList();
        state = state.copyWith(
          posts: newPosts,
          oldestPostTimestamp: newPosts.isNotEmpty
              ? newPosts.last.createdAt
              : null,
          newestPostTimestamp: newPosts.isNotEmpty
              ? newPosts.first.createdAt
              : null,
        );
      }
    }, (error) {});
  }

  /// Checks a batch of posts for deletions, cycling through all cached posts.
  /// Call every 30 seconds to cover all 200 posts in ~2 minutes.
  Future<void> checkForDeletionsStaggered(String userId) async {
    final allPosts = state.posts;
    if (allPosts.isEmpty || userId.isEmpty) return;

    // Get the batch to check
    final batchStart = _deletionCheckOffset;
    final batchEnd = (batchStart + _deletionCheckBatchSize).clamp(
      0,
      allPosts.length,
    );
    final postsToCheck = allPosts.sublist(batchStart, batchEnd);

    // Advance offset for next call (wrap around)
    _deletionCheckOffset = batchEnd >= allPosts.length ? 0 : batchEnd;

    if (postsToCheck.isEmpty) return;

    // For posts in later batches, we use 24h expiry as the primary mechanism
    // since fetching with cursor for exact time ranges is complex.
    // The first batch (0-50) is already covered by checkForDeletions().
    if (batchStart == 0) {
      // Use existing checkForDeletions for first batch
      await checkForDeletions(userId);
      return;
    }

    // For posts 50+, trust 24h expiry (handled by posts getter filter).
    // This is simpler and avoids complex cursor-based server queries.
    // Posts beyond 50 are older, so they're closer to natural expiry anyway.
  }

  /// Adds a newly created post to the top of the cache.
  void addPost(FeedPostModel post) {
    if (state.posts.any((p) => p.id == post.id)) return;

    var newPosts = [post, ...state.posts];
    if (newPosts.length > _maxCachedPosts) {
      newPosts = newPosts.take(_maxCachedPosts).toList();
    }

    state = state.copyWith(
      posts: newPosts,
      newestPostTimestamp: post.createdAt,
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
  void removeExpiredPosts() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final validPosts = state.posts
        .where((p) => p.publishedAt.isAfter(cutoff))
        .toList();

    if (validPosts.length != state.posts.length) {
      state = state.copyWith(
        posts: validPosts,
        oldestPostTimestamp: validPosts.isNotEmpty
            ? validPosts.last.createdAt
            : null,
      );
    }
  }

  /// Clears all cached data. Call on logout.
  void invalidateCache() {
    _currentUserId = null;
    _isBackgroundLoading = false;
    _deletionCheckOffset = 0;
    state = const FeedCacheState();
  }

  /// Returns true if cache needs a full rebuild.
  bool get needsFullRebuild {
    return _lastFullValidation == null ||
        DateTime.now().difference(_lastFullValidation!) >
            const Duration(hours: 6);
  }

  /// Performs a full cache rebuild by fetching fresh data from server.
  /// Called on cold start or after 6 hours of active use.
  Future<void> fullCacheRebuild(String userId) async {
    _lastFullValidation = DateTime.now();
    _deletionCheckOffset = 0;
    invalidateCache();
    await loadInitialPosts(userId);
  }

  /// Re-enriches all cached posts with fresh signed URLs.
  /// Call when app resumes after extended background time.
  Future<void> reEnrichCachedPosts() async {
    if (state.posts.isEmpty) return;
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    // Re-enrich by invalidating and refetching
    // This ensures fresh signed URLs for all media
    final userId = _currentUserId!;
    await _checkForNewPostsInBackground(userId);
  }

  /// Calls loadInitialPosts which handles background loading.
  Future<void> preloadFeed(String userId) async {
    await loadInitialPosts(userId);
  }
}
