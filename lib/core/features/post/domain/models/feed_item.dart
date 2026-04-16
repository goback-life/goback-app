import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';

/// A unified feed item that can be either a post or a lockout placeholder.
///
/// Lockout placeholders are rendered from active friend lockout sessions
/// (no rows in the posts table). They appear chronologically alongside
/// real posts and disappear when the lockout ends.
sealed class FeedItem {
  const FeedItem();

  /// Timestamp used for chronological sorting in the feed.
  DateTime get sortTimestamp;

  /// Unique key for use in list widgets.
  String get itemKey;
}

class FeedItemPost extends FeedItem {
  const FeedItemPost(this.post);
  final FeedPostModel post;

  @override
  DateTime get sortTimestamp => post.createdAt;

  @override
  String get itemKey => 'post_${post.id}';
}

class FeedItemLockoutPlaceholder extends FeedItem {
  const FeedItemLockoutPlaceholder(this.lockout);
  final LockoutSessionModel lockout;

  @override
  DateTime get sortTimestamp => lockout.startedAt;

  @override
  String get itemKey => 'lockout_${lockout.id}';
}
