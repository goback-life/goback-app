import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class TargetUserCircleSizeLimitException extends ConnectionException {
  const TargetUserCircleSizeLimitException([
    super.message =
        'The user you are trying to reach has reached the maximum circle size',
  ]);
}
