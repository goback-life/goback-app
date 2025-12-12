import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class ConnectionUnauthorizedException extends ConnectionException {
  const ConnectionUnauthorizedException([String? code])
    : super('Connection access unauthorized', code: code);
}
