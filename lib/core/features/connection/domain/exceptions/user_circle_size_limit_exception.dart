import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class UserCircleSizeLimitException extends ConnectionException {
  const UserCircleSizeLimitException([
    super.message = 'You have reached the maximum circle size',
  ]);
}
