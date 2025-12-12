import 'package:cloudless/core/features/post/domain/exceptions/feed_post_exceptions.dart';

class FeedPostPermissionException extends FeedPostException {
  const FeedPostPermissionException([
    super.message = 'Insufficient permissions to access feed',
  ]);
}
