import 'package:cloudless/core/exceptions/main_exception.dart';

class NotificationException extends MainException {
  const NotificationException([String? message, String? code])
    : super(message ?? 'Notification operation failed', code: code);
}
