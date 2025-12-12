import 'package:cloudless/core/features/post/domain/exceptions/feed_post_exceptions.dart';

class FeedPostUnauthorizedException extends FeedPostException {
  const FeedPostUnauthorizedException([
    super.message = 'Unauthorized access to feed',
  ]);
}
