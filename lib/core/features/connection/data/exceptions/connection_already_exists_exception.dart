import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class ConnectionAlreadyExistsException extends ConnectionException {
  const ConnectionAlreadyExistsException([
    super.message = 'Connection already exists',
    String? code,
  ]) : super(code: code);
}
