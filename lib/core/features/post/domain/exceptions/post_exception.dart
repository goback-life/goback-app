import 'package:cloudless/core/exceptions/main_exception.dart';

class PostException extends MainException {
  const PostException([String? message, String? code])
    : super(message ?? 'Post operation failed', code: code);
}
