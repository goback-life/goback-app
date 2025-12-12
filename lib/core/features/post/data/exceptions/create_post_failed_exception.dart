import 'package:cloudless/core/exceptions/main_exception.dart';

class CreatePostFailedException extends MainException {
  const CreatePostFailedException([String? message, String? code])
    : super(message ?? 'Failed to create post', code: code);
}
