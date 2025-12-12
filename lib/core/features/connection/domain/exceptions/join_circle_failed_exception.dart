import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class JoinCircleFailedException extends ConnectionException {
  const JoinCircleFailedException([
    super.message = 'Failed to join circle. Please try again.',
  ]);
}
