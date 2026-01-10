import 'package:cloudless/core/features/notification/domain/exceptions/notification_exception.dart';

class NotificationUnauthorizedException extends NotificationException {
  const NotificationUnauthorizedException([super.message, super.code]);
}

