import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_posts_cache_provider.g.dart';

/// Cache provider for calendar posts to avoid redundant database calls.
/// Maintains a list of all lockout posts for the current user's selected month.
/// This cache is shared across the app (calendar view, post detail, etc.).
@Riverpod(keepAlive: true)
class CalendarPostsCache extends _$CalendarPostsCache {
  String? _currentUserId;

  @override
  List<CalendarPostModel> build() => [];

  /// Updates the cache with a new list of calendar posts for a specific user.
  /// If the userId changes, the cache is automatically cleared first.
  void updateCache(List<CalendarPostModel> posts, {required String userId}) {
    // Clear cache if user changed
    if (_currentUserId != null && _currentUserId != userId) {
      state = [];
      _currentUserId = userId;
    }

    // Update current user if not set
    _currentUserId ??= userId;

    // Update the state with new posts
    state = posts;
  }

  /// Merges fresh posts into the cache for a visible date range.
  ///
  /// Removes any existing cached posts within [rangeStart]..[rangeEnd]
  /// and replaces them with [newPosts]. Posts outside the range are kept,
  /// so the cache accumulates data across months.
  void mergePosts(
    List<CalendarPostModel> newPosts, {
    required String userId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (_currentUserId != null && _currentUserId != userId) {
      state = [];
      _currentUserId = userId;
    }
    _currentUserId ??= userId;

    final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    // Keep posts outside the fetched range, replace those inside
    final kept = state.where((p) {
      final d = DateTime(
        p.publishedAt.year,
        p.publishedAt.month,
        p.publishedAt.day,
      );
      return d.isBefore(start) || d.isAfter(end);
    }).toList();

    state = [...kept, ...newPosts];
  }

  /// Appends posts to the cache without clearing existing posts.
  /// Useful for incremental loading (e.g., loading 10 more posts).
  /// Duplicates are automatically removed based on post ID.
  void appendPosts(List<CalendarPostModel> newPosts) {
    final existingIds = state.map((p) => p.postId).toSet();
    final uniqueNewPosts = newPosts
        .where((p) => !existingIds.contains(p.postId))
        .toList();

    state = [...state, ...uniqueNewPosts];
  }

  /// Gets the published date for a specific post if it exists in the calendar.
  /// Returns null if the post is not in the calendar.
  DateTime? getPostCalendarDate(String postId) {
    try {
      return state.firstWhere((post) => post.postId == postId).publishedAt;
    } catch (e) {
      return null;
    }
  }

  /// Adds a single post to the cache optimistically (without DB reload).
  /// If a post already exists for the same date, it will be replaced.
  /// This is useful for optimistic UI updates after creating a lockout post.
  void addPostOptimistically(CalendarPostModel post) {
    // Remove any existing post for the same date (max 1 post per day)
    final postDate = DateTime(
      post.publishedAt.year,
      post.publishedAt.month,
      post.publishedAt.day,
    );

    final filtered = state.where((p) {
      final pDate = DateTime(
        p.publishedAt.year,
        p.publishedAt.month,
        p.publishedAt.day,
      );
      return !pDate.isAtSameMomentAs(postDate);
    }).toList();

    // Add the new post
    state = [...filtered, post];
  }

  /// Removes a single post from the cache optimistically (without DB reload).
  /// This is useful for optimistic UI updates after removing a post.
  void removePostOptimistically(String postId) {
    state = state.where((post) => post.postId != postId).toList();
  }

  /// Clears the cache.
  /// Useful when switching between months or users.
  void clearCache() {
    _currentUserId = null;
    state = [];
  }

  /// Gets the current cached user ID.
  String? get currentUserId => _currentUserId;

  /// Gets all posts sorted by published date in ascending order.
  List<CalendarPostModel> getSortedPosts() {
    final sorted = List<CalendarPostModel>.from(state)
      ..sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
    return sorted;
  }

  /// Gets all posts sorted by published date for a specific author.
  List<CalendarPostModel> getSortedPostsByAuthor(String authorId) {
    final filtered = state.where((post) => post.authorId == authorId).toList()
      ..sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
    return filtered;
  }

  /// Finds the next post after the given date.
  /// Returns null if there's no next post.
  CalendarPostModel? getNextPost(DateTime currentDate, {String? authorId}) {
    final sorted = authorId != null
        ? getSortedPostsByAuthor(authorId)
        : getSortedPosts();
    final normalizedDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    for (final post in sorted) {
      final postDate = DateTime(
        post.publishedAt.year,
        post.publishedAt.month,
        post.publishedAt.day,
      );
      if (postDate.isAfter(normalizedDate)) {
        return post;
      }
    }
    return null;
  }

  /// Finds the previous post before the given date.
  /// Returns null if there's no previous post.
  CalendarPostModel? getPreviousPost(DateTime currentDate, {String? authorId}) {
    final sorted = authorId != null
        ? getSortedPostsByAuthor(authorId)
        : getSortedPosts();
    final normalizedDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    for (var i = sorted.length - 1; i >= 0; i--) {
      final post = sorted[i];
      final postDate = DateTime(
        post.publishedAt.year,
        post.publishedAt.month,
        post.publishedAt.day,
      );
      if (postDate.isBefore(normalizedDate)) {
        return post;
      }
    }
    return null;
  }

  /// Checks if the current post is near the end of the cached posts for navigation.
  /// Returns true if the post is within the last [threshold] posts (default: 3).
  bool isNearEnd(DateTime currentDate, {String? authorId, int threshold = 3}) {
    final sorted = authorId != null
        ? getSortedPostsByAuthor(authorId)
        : getSortedPosts();
    if (sorted.isEmpty || sorted.length <= threshold) {
      return false;
    }

    final normalizedDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final currentIndex = sorted.indexWhere((post) {
      final postDate = DateTime(
        post.publishedAt.year,
        post.publishedAt.month,
        post.publishedAt.day,
      );
      return postDate.isAtSameMomentAs(normalizedDate);
    });

    if (currentIndex == -1) {
      return false;
    }

    return currentIndex >= sorted.length - threshold;
  }

  /// Checks if the current post is near the beginning of the cached posts for navigation.
  /// Returns true if the post is within the first [threshold] posts (default: 3).
  bool isNearBeginning(
    DateTime currentDate, {
    String? authorId,
    int threshold = 3,
  }) {
    final sorted = authorId != null
        ? getSortedPostsByAuthor(authorId)
        : getSortedPosts();
    if (sorted.isEmpty || sorted.length <= threshold) {
      return false;
    }

    final normalizedDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final currentIndex = sorted.indexWhere((post) {
      final postDate = DateTime(
        post.publishedAt.year,
        post.publishedAt.month,
        post.publishedAt.day,
      );
      return postDate.isAtSameMomentAs(normalizedDate);
    });

    if (currentIndex == -1) {
      return false;
    }

    return currentIndex < threshold;
  }
}
