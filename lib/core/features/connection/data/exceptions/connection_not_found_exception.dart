import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class ConnectionNotFoundException extends ConnectionException {
  const ConnectionNotFoundException([
    super.message = 'Connection not found',
    String? code,
  ]) : super(code: code);
}
