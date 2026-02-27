import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class ConnectionRequestException extends ConnectionException {
  const ConnectionRequestException([
    super.message = 'Connection request failed',
  ]);
}
