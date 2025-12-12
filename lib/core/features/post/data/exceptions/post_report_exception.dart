import 'package:cloudless/core/exceptions/main_exception.dart';

class PostReportException extends MainException {
  const PostReportException([String? message, String? code])
    : super(message ?? 'Post report operation failed', code: code);
}
