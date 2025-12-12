import 'package:cloudless/core/exceptions/main_exception.dart';

class PostUploadFailedException extends MainException {
  const PostUploadFailedException([String? message, String? code])
    : super(message ?? 'Post upload failed', code: code);
}
