import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';

/// Creates a fake FeedPostModel for testing.
///
/// [publishedAt] controls when the post was published (for 24h expiry tests).
/// [id] defaults to a UUID-like string based on index if not provided.
FeedPostModel createFakePost({
  String? id,
  required DateTime publishedAt,
  String authorId = 'author-123',
  String? authorUsername,
  ContentType contentType = ContentType.image,
}) {
  final postId = id ?? 'post-${publishedAt.millisecondsSinceEpoch}';
  return FeedPostModel(
    id: postId,
    authorId: authorId,
    publishedAt: publishedAt,
    publishedTimezone: 'UTC',
    createdAt: publishedAt,
    updatedAt: publishedAt,
    taggedUsernames: const [],
    taggedUserIds: const [],
    excludedUserIds: const [],
    thumbnailWidth: 1080,
    thumbnailHeight: 1920,
    contentType: contentType,
    isAuthorConnected: true,
    authorUsername: authorUsername,
    imageUrl: 'https://example.com/$postId.jpg',
  );
}

/// Creates a list of fake posts with staggered timestamps.
///
/// [count] - number of posts to create
/// [startTime] - the newest post's publishedAt time
/// [interval] - time between each post (default 1 hour)
///
/// Posts are ordered newest-first (index 0 = newest).
List<FeedPostModel> createFakePostList({
  required int count,
  required DateTime startTime,
  Duration interval = const Duration(hours: 1),
}) {
  return List.generate(count, (index) {
    final publishedAt = startTime.subtract(interval * index);
    return createFakePost(
      id: 'post-$index',
      publishedAt: publishedAt,
    );
  });
}

/// Creates posts that span across the 24-hour expiry boundary.
///
/// Returns a record with:
/// - [valid]: posts within 24 hours
/// - [expired]: posts older than 24 hours
/// - [all]: all posts combined (valid first, then expired)
({
  List<FeedPostModel> valid,
  List<FeedPostModel> expired,
  List<FeedPostModel> all,
}) createPostsWithExpiry({
  int validCount = 3,
  int expiredCount = 2,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();

  // Valid posts: 1-23 hours old
  final valid = List.generate(validCount, (index) {
    final hoursAgo = 1 + (index * 6); // 1h, 7h, 13h, 19h...
    return createFakePost(
      id: 'valid-$index',
      publishedAt: effectiveNow.subtract(Duration(hours: hoursAgo)),
    );
  });

  // Expired posts: 25+ hours old
  final expired = List.generate(expiredCount, (index) {
    final hoursAgo = 25 + (index * 2); // 25h, 27h, 29h...
    return createFakePost(
      id: 'expired-$index',
      publishedAt: effectiveNow.subtract(Duration(hours: hoursAgo)),
    );
  });

  return (
    valid: valid,
    expired: expired,
    all: [...valid, ...expired],
  );
}
