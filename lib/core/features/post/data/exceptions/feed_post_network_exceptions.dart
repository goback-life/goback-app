import 'package:cloudless/core/features/post/domain/exceptions/feed_post_exceptions.dart';

class FeedPostNetworkException extends FeedPostException {
  const FeedPostNetworkException([
    super.message = 'Network error while fetching posts',
  ]);
}
