import 'package:cloudless/core/exceptions/main_exception.dart';

/// Exception thrown when user exceeds post rate limit (50 posts per hour).
class PostRateLimitException extends MainException {
  const PostRateLimitException([
    super.message = 'Rate limit exceeded: maximum 50 posts per hour',
  ]) : super(code: 'P0001');
}
