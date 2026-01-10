import 'package:cloudless/core/features/notification/domain/exceptions/notification_exception.dart';

class NotificationNetworkException extends NotificationException {
  const NotificationNetworkException(
      [super.message = 'Network error while fetching notifications']);
}

