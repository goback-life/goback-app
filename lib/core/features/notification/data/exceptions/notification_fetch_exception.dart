import 'package:cloudless/core/features/notification/domain/exceptions/notification_exception.dart';

class NotificationFetchException extends NotificationException {
  const NotificationFetchException(
      [super.message = 'Failed to fetch notifications']);
}

