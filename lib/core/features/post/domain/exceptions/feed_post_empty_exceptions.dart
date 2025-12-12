import 'package:cloudless/core/features/post/domain/exceptions/feed_post_exceptions.dart';

class FeedPostEmptyException extends FeedPostException {
  const FeedPostEmptyException([
    super.message = 'No posts available for today',
  ]);
}
