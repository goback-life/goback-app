import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_posts_cache_provider.g.dart';

/// Strips time components, returning midnight of the given date.
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Cache provider for calendar posts to avoid redundant database calls.
/// Maintains a list of all lockout posts for the current user's selected month.
/// This cache is shared across the app (calendar view, post detail, etc.).
@Riverpod(keepAlive: true)
class CalendarPostsCache extends _$CalendarPostsCache {
  String? _currentUserId;

  @override
  List<CalendarPostModel> build() => [];

  /// Clears state when the user changes, sets _currentUserId.
  void _ensureUser(String userId) {
    if (_currentUserId != null && _currentUserId != userId) {
      state = [];
    }
    _currentUserId = userId;
  }

  /// Returns sorted posts, optionally filtered by author.
  List<CalendarPostModel> _sortedBy({String? authorId}) {
    final source = authorId != null
        ? state.where((p) => p.authorId == authorId).toList()
        : List<CalendarPostModel>.from(state);
    return source..sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
  }

  /// Finds the index of the post matching [date] in [sorted].
  /// Returns -1 if not found.
  int _indexOfDate(List<CalendarPostModel> sorted, DateTime date) {
    final d = _dateOnly(date);
    return sorted.indexWhere((p) => _dateOnly(p.publishedAt).isAtSameMomentAs(d));
  }

  /// Updates the cache with a new list of calendar posts for a specific user.
  void updateCache(List<CalendarPostModel> posts, {required String userId}) {
    _ensureUser(userId);
    state = posts;
  }

  /// Merges fresh posts into the cache for a visible date range.
  ///
  /// Removes any existing cached posts within [rangeStart]..[rangeEnd]
  /// and replaces them with [newPosts]. Posts outside the range are kept.
  void mergePosts(
    List<CalendarPostModel> newPosts, {
    required String userId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    _ensureUser(userId);
    final start = _dateOnly(rangeStart);
    final end = _dateOnly(rangeEnd);

    final kept = state.where((p) {
      final d = _dateOnly(p.publishedAt);
      return d.isBefore(start) || d.isAfter(end);
    }).toList();

    state = [...kept, ...newPosts];
  }

  /// Appends posts to the cache without clearing existing posts.
  /// Duplicates are automatically removed based on post ID.
  void appendPosts(List<CalendarPostModel> newPosts) {
    final existingIds = state.map((p) => p.postId).toSet();
    final unique = newPosts.where((p) => !existingIds.contains(p.postId));
    state = [...state, ...unique];
  }

  /// Gets the published date for a specific post if it exists in the calendar.
  DateTime? getPostCalendarDate(String postId) {
    try {
      return state.firstWhere((post) => post.postId == postId).publishedAt;
    } catch (_) {
      return null;
    }
  }

  /// Adds a single post to the cache optimistically (without DB reload).
  void addPostOptimistically(CalendarPostModel post) {
    final postDate = _dateOnly(post.publishedAt);
    final filtered = state.where(
      (p) => !_dateOnly(p.publishedAt).isAtSameMomentAs(postDate),
    ).toList();
    state = [...filtered, post];
  }

  /// Removes a single post from the cache optimistically (without DB reload).
  void removePostOptimistically(String postId) {
    state = state.where((post) => post.postId != postId).toList();
  }

  /// Clears the cache.
  void clearCache() {
    _currentUserId = null;
    state = [];
  }

  /// Gets the current cached user ID.
  String? get currentUserId => _currentUserId;

  /// Gets all posts sorted by published date in ascending order.
  List<CalendarPostModel> getSortedPosts() => _sortedBy();

  /// Gets all posts sorted by published date for a specific author.
  List<CalendarPostModel> getSortedPostsByAuthor(String authorId) =>
      _sortedBy(authorId: authorId);

  /// Finds the next post after the given date.
  CalendarPostModel? getNextPost(DateTime currentDate, {String? authorId}) {
    final sorted = _sortedBy(authorId: authorId);
    final d = _dateOnly(currentDate);
    for (final post in sorted) {
      if (_dateOnly(post.publishedAt).isAfter(d)) return post;
    }
    return null;
  }

  /// Finds the previous post before the given date.
  CalendarPostModel? getPreviousPost(DateTime currentDate, {String? authorId}) {
    final sorted = _sortedBy(authorId: authorId);
    final d = _dateOnly(currentDate);
    for (var i = sorted.length - 1; i >= 0; i--) {
      if (_dateOnly(sorted[i].publishedAt).isBefore(d)) return sorted[i];
    }
    return null;
  }

  /// Checks if the current post is near the end of the cached posts.
  bool isNearEnd(DateTime currentDate, {String? authorId, int threshold = 3}) {
    final sorted = _sortedBy(authorId: authorId);
    if (sorted.length <= threshold) return false;
    final idx = _indexOfDate(sorted, currentDate);
    return idx != -1 && idx >= sorted.length - threshold;
  }

  /// Checks if the current post is near the beginning of the cached posts.
  bool isNearBeginning(
    DateTime currentDate, {
    String? authorId,
    int threshold = 3,
  }) {
    final sorted = _sortedBy(authorId: authorId);
    if (sorted.length <= threshold) return false;
    final idx = _indexOfDate(sorted, currentDate);
    return idx != -1 && idx < threshold;
  }
}
