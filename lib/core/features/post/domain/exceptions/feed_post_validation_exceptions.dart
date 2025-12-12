import 'package:cloudless/core/features/post/domain/exceptions/feed_post_exceptions.dart';

class FeedPostValidationException extends FeedPostException {
  const FeedPostValidationException([
    super.message = 'Invalid feed request parameters',
  ]);
}
