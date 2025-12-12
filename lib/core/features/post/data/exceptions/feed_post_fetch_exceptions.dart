import 'package:cloudless/core/features/post/domain/exceptions/feed_post_exceptions.dart';

class FeedPostFetchException extends FeedPostException {
  const FeedPostFetchException([super.message = 'Failed to fetch feed posts']);
}
