import 'package:cloudless/core/exceptions/main_exception.dart';

class InvalidMediaException extends MainException {
  const InvalidMediaException([String? message, String? code])
    : super(message ?? 'Invalid media file provided', code: code);
}
