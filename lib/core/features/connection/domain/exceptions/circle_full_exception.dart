import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class CircleFullException extends ConnectionException {
  const CircleFullException([
    super.message = 'Circle is full (150 members max)',
  ]);
}
