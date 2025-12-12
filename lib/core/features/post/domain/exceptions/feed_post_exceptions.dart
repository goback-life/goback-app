import 'package:cloudless/core/exceptions/main_exception.dart';

class FeedPostException extends MainException {
  const FeedPostException([String? message, String? code])
    : super(message ?? 'Feed post operation failed', code: code);
}
