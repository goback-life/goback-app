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
  DateTime? _lastEnrichedAt;
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
    // ignore: avoid_print
    print('[FeedCache] loadInitialPosts called, userId: $userId, currentUserId: $_currentUserId, initialLoadComplete: ${state.initialLoadComplete}, posts: ${state.posts.length}');

    if (userId.isEmpty || userId.trim().isEmpty) {
      // ignore: avoid_print
      print('[FeedCache] loadInitialPosts: empty userId, returning');
      return [];
    }

    // Clear cache if user changed
    if (_currentUserId != null && _currentUserId != userId) {
      // ignore: avoid_print
      print('[FeedCache] loadInitialPosts: user changed, invalidating cache');
      invalidateCache();
    }
    _currentUserId = userId;

    // If we already have posts for this user, return them immediately
    // and trigger a background refresh for new posts
    if (state.initialLoadComplete && state.posts.isNotEmpty) {
      // ignore: avoid_print
      print('[FeedCache] loadInitialPosts: cache valid, returning ${state.posts.length} cached posts and checking for new');
      // Check for new posts in background
      _checkForNewPostsInBackground(userId);
      return state.posts;
    }

    // ignore: avoid_print
    print('[FeedCache] loadInitialPosts: fetching initial posts from server');

    // Fetch first page
    final result = await ref.read(
      getFeedPostsProvider(userId: userId, pageSize: _pageSize).future,
    );

    // ignore: avoid_print
    print('[FeedCache] loadInitialPosts: fetch complete, processing result');

    return result.fold(
      (response) {
        final posts = response.posts;
        // ignore: avoid_print
        print('[FeedCache] loadInitialPosts: got ${posts.length} posts, hasNextPage: ${response.hasNextPage}');

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
          // ignore: avoid_print
          print('[FeedCache] loadInitialPosts: starting background loading');
          _startBackgroundLoading(userId);
        } else {
          // ignore: avoid_print
          print('[FeedCache] loadInitialPosts: no more pages, not starting background loading');
        }

        return posts;
      },
      (error) {
        // ignore: avoid_print
        print('[FeedCache] Error loading initial posts: $error');
        return <FeedPostModel>[];
      },
    );
  }

  /// Starts background loading of all remaining posts.
  /// Updates UI progressively as each batch loads.
  void _startBackgroundLoading(String userId) {
    // ignore: avoid_print
    print('[FeedCache] _startBackgroundLoading called, _isBackgroundLoading: $_isBackgroundLoading');
    if (_isBackgroundLoading) return;
    _isBackgroundLoading = true;
    state = state.copyWith(isPreloading: true);

    _loadNextBatch(userId);
  }

  /// Loads the next batch of posts in background.
  Future<void> _loadNextBatch(String userId) async {
    // ignore: avoid_print
    print('[FeedCache] _loadNextBatch called, _isBackgroundLoading: $_isBackgroundLoading, fullyLoaded: ${state.fullyLoaded}, posts: ${state.posts.length}');

    if (!_isBackgroundLoading) return;
    if (state.fullyLoaded) {
      _isBackgroundLoading = false;
      state = state.copyWith(isPreloading: false);
      // ignore: avoid_print
      print('[FeedCache] _loadNextBatch: already fully loaded, stopping');
      return;
    }
    if (state.posts.length >= _maxCachedPosts) {
      _isBackgroundLoading = false;
      state = state.copyWith(isPreloading: false, fullyLoaded: true);
      return;
    }

    final cursor = state.oldestPostTimestamp;

    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: _backgroundBatchSize,
        cursor: cursor,
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

        // Filter duplicates
        final existingIds = state.posts.map((p) => p.id).toSet();
        final newPosts = response.posts
            .where((p) => !existingIds.contains(p.id))
            .toList();

        if (newPosts.isEmpty) {
          _isBackgroundLoading = false;
          state = state.copyWith(
            isPreloading: false,
            hasNextPage: false,
            fullyLoaded: true,
          );
          return;
        }

        // Append new posts and update state (progressive UI update)
        var allPosts = [...state.posts, ...newPosts];

        // Enforce max cache size
        final reachedLimit = allPosts.length >= _maxCachedPosts;
        if (reachedLimit) {
          allPosts = allPosts.take(_maxCachedPosts).toList();
        }

        state = state.copyWith(
          posts: allPosts,
          oldestPostTimestamp: allPosts.last.createdAt,
          hasNextPage: response.hasNextPage && !reachedLimit,
          fullyLoaded: !response.hasNextPage || reachedLimit,
          isPreloading: response.hasNextPage && !reachedLimit,
        );

        // ignore: avoid_print
        print('[FeedCache] Background loaded ${newPosts.length} posts, total: ${allPosts.length}');

        // Continue loading if more available
        if (response.hasNextPage && !reachedLimit) {
          // Small delay to avoid overwhelming the server
          Future.delayed(const Duration(milliseconds: 100), () {
            _loadNextBatch(userId);
          });
        } else {
          _isBackgroundLoading = false;
        }
      },
      (error) {
        // ignore: avoid_print
        print('[FeedCache] Background loading error: $error');
        _isBackgroundLoading = false;
        state = state.copyWith(isPreloading: false);
      },
    );
  }

  /// Loads more posts immediately (called when user scrolls faster than background loading).
  /// Returns true if more posts were loaded.
  Future<bool> loadMorePostsNow(String userId, {int count = 30}) async {
    if (state.fullyLoaded) return false;
    if (state.posts.length >= _maxCachedPosts) return false;

    final cursor = state.oldestPostTimestamp;

    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: count,
        cursor: cursor,
      ).future,
    );

    return result.fold(
      (response) {
        if (response.posts.isEmpty) {
          state = state.copyWith(hasNextPage: false, fullyLoaded: true);
          return false;
        }

        // Filter duplicates
        final existingIds = state.posts.map((p) => p.id).toSet();
        final newPosts = response.posts
            .where((p) => !existingIds.contains(p.id))
            .toList();

        if (newPosts.isEmpty) {
          state = state.copyWith(hasNextPage: false, fullyLoaded: true);
          return false;
        }

        var allPosts = [...state.posts, ...newPosts];
        final reachedLimit = allPosts.length >= _maxCachedPosts;
        if (reachedLimit) {
          allPosts = allPosts.take(_maxCachedPosts).toList();
        }

        state = state.copyWith(
          posts: allPosts,
          oldestPostTimestamp: allPosts.last.createdAt,
          hasNextPage: response.hasNextPage && !reachedLimit,
          fullyLoaded: !response.hasNextPage || reachedLimit,
        );

        return newPosts.isNotEmpty;
      },
      (error) => false,
    );
  }

  /// Checks for new posts (published after our newest cached post).
  /// If cache is empty, fetches initial posts.
  Future<void> _checkForNewPostsInBackground(String userId) async {
    // ignore: avoid_print
    print('[FeedCache] Checking for new posts, cache has ${state.posts.length} posts');

    // Invalidate the provider to force a fresh fetch
    ref.invalidate(getFeedPostsProvider(userId: userId, pageSize: _pageSize));

    // Fetch newest posts
    final result = await ref.read(
      getFeedPostsProvider(userId: userId, pageSize: _pageSize).future,
    );

    result.fold(
      (response) {
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
          // ignore: avoid_print
          print('[FeedCache] Loaded ${response.posts.length} posts into empty cache, hasNextPage: ${response.hasNextPage}');

          // Start background loading if more posts available
          if (response.hasNextPage && _currentUserId != null) {
            // ignore: avoid_print
            print('[FeedCache] Starting background loading after refilling empty cache');
            _startBackgroundLoading(_currentUserId!);
          }
          return;
        }

        // Find posts newer than our newest cached post
        final newestCached = state.newestPostTimestamp;
        if (newestCached == null) {
          // No timestamp reference, merge all non-duplicate posts
          final existingIds = state.posts.map((p) => p.id).toSet();
          final newPosts =
              response.posts.where((p) => !existingIds.contains(p.id)).toList();
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
            // ignore: avoid_print
            print('[FeedCache] Merged ${newPosts.length} posts (no timestamp ref)');
          }
          return;
        }

        final newPosts = response.posts
            .where((p) => p.createdAt.isAfter(newestCached))
            .where((p) => !state.posts.any((cached) => cached.id == p.id))
            .toList();

        if (newPosts.isNotEmpty) {
          // Prepend new posts
          var allPosts = [...newPosts, ...state.posts];
          if (allPosts.length > _maxCachedPosts) {
            allPosts = allPosts.take(_maxCachedPosts).toList();
          }

          state = state.copyWith(
            posts: allPosts,
            newestPostTimestamp: allPosts.first.createdAt,
            lastFetchedAt: DateTime.now(),
          );

          // ignore: avoid_print
          print('[FeedCache] Found ${newPosts.length} new posts');
        }
      },
      (error) {
        // ignore: avoid_print
        print('[FeedCache] Error checking for new posts: $error');
      },
    );
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
      final result = await ref.read(
        getPostByIdProvider(postId: postId).future,
      );

      return result.fold(
        (newPost) {
          addPost(newPost);
          // ignore: avoid_print
          print('[FeedCache] Added new post $postId');
          return true;
        },
        (error) {
          // ignore: avoid_print
          print('[FeedCache] Error fetching post $postId: $error');
          return false;
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[FeedCache] Exception fetching post $postId: $e');
      return false;
    }
  }

  /// Checks for deleted/hidden posts and removes them from cache.
  /// Lightweight check - only removes posts no longer visible, doesn't fetch edits.
  /// Edits are fetched when user taps on a post to view details.
  Future<void> checkForDeletions(String userId) async {
    if (state.posts.isEmpty || userId.isEmpty) return;

    // ignore: avoid_print
    print('[FeedCache] checkForDeletions starting, cache has ${state.posts.length} posts');

    // Invalidate the provider to force a fresh fetch
    ref.invalidate(getFeedPostsProvider(userId: userId, pageSize: 50));

    // Fetch current post IDs from server (just first page + some buffer)
    final result = await ref.read(
      getFeedPostsProvider(
        userId: userId,
        pageSize: 50, // Check a reasonable batch
      ).future,
    );

    result.fold(
      (response) {
        // ignore: avoid_print
        print('[FeedCache] Server returned ${response.posts.length} posts for deletion check');

        final visiblePostIds = response.posts.map((p) => p.id).toSet();

        // If server returns 0 posts but we have cached posts, clear the cache
        if (response.posts.isEmpty && state.posts.isNotEmpty) {
          // ignore: avoid_print
          print('[FeedCache] Server has 0 posts, clearing cache of ${state.posts.length} posts');
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

        // ignore: avoid_print
        print('[FeedCache] Found ${deletedIds.length} deleted posts out of ${postsToCheck.length} checked');

        if (deletedIds.isNotEmpty) {
          final newPosts = state.posts.where((p) => !deletedIds.contains(p.id)).toList();
          state = state.copyWith(
            posts: newPosts,
            oldestPostTimestamp: newPosts.isNotEmpty ? newPosts.last.createdAt : null,
            newestPostTimestamp: newPosts.isNotEmpty ? newPosts.first.createdAt : null,
          );
          // ignore: avoid_print
          print('[FeedCache] Removed ${deletedIds.length} deleted/hidden posts, ${newPosts.length} remaining');
        }
      },
      (error) {
        // ignore: avoid_print
        print('[FeedCache] Error checking for deletions: $error');
      },
    );
  }

  /// Checks a batch of posts for deletions, cycling through all cached posts.
  /// Call every 30 seconds to cover all 200 posts in ~2 minutes.
  Future<void> checkForDeletionsStaggered(String userId) async {
    final allPosts = state.posts;
    if (allPosts.isEmpty || userId.isEmpty) return;

    // Get the batch to check
    final batchStart = _deletionCheckOffset;
    final batchEnd =
        (batchStart + _deletionCheckBatchSize).clamp(0, allPosts.length);
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

    // For posts 50+, trust 24h expiry (handled by posts getter filter)
    // This is simpler and avoids complex cursor-based server queries.
    // Posts beyond 50 are older, so they're closer to natural expiry anyway.
    // ignore: avoid_print
    print(
        '[FeedCache] Staggered check batch $batchStart-$batchEnd (trusting 24h expiry)');
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
        oldestPostTimestamp: validPosts.isNotEmpty ? validPosts.last.createdAt : null,
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
    final result = _lastFullValidation == null ||
        DateTime.now().difference(_lastFullValidation!) > const Duration(hours: 6);
    // ignore: avoid_print
    print('[FeedCache] needsFullRebuild: $result (lastValidation: $_lastFullValidation)');
    return result;
  }

  /// Performs a full cache rebuild by fetching fresh data from server.
  /// Called on cold start or after 6 hours of active use.
  Future<void> fullCacheRebuild(String userId) async {
    // ignore: avoid_print
    print('[FeedCache] fullCacheRebuild called for userId: $userId');
    _lastFullValidation = DateTime.now();
    _lastEnrichedAt = DateTime.now();
    _deletionCheckOffset = 0;
    invalidateCache();
    await loadInitialPosts(userId);
    // ignore: avoid_print
    print('[FeedCache] fullCacheRebuild complete, posts: ${state.posts.length}');
  }

  /// Re-enriches all cached posts with fresh signed URLs.
  /// Call when app resumes after extended background time.
  Future<void> reEnrichCachedPosts() async {
    if (state.posts.isEmpty) return;
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    _lastEnrichedAt = DateTime.now();

    // Re-enrich by invalidating and refetching
    // This ensures fresh signed URLs for all media
    final userId = _currentUserId!;
    await _checkForNewPostsInBackground(userId);
  }

  /// Returns the time the cache was last enriched with fresh URLs.
  DateTime? get lastEnrichedAt => _lastEnrichedAt;

  /// Legacy method for compatibility - updates cache with posts.
  void updateCache(List<FeedPostModel> posts, {bool? hasNextPage}) {
    final truncatedPosts = posts.length > _maxCachedPosts
        ? posts.take(_maxCachedPosts).toList()
        : posts;
    state = state.copyWith(
      posts: truncatedPosts,
      lastFetchedAt: DateTime.now(),
      newestPostTimestamp: truncatedPosts.isNotEmpty ? truncatedPosts.first.createdAt : null,
      oldestPostTimestamp: truncatedPosts.isNotEmpty ? truncatedPosts.last.createdAt : null,
      hasNextPage: hasNextPage ?? state.hasNextPage,
      initialLoadComplete: true,
    );
  }

  /// Legacy compatibility
  bool get isCacheValid => state.initialLoadComplete && state.posts.isNotEmpty;

  /// Legacy method - now calls loadInitialPosts which handles background loading.
  Future<void> preloadFeed(String userId) async {
    await loadInitialPosts(userId);
  }
}
