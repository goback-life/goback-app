import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class UsersAlreadyConnectedException extends ConnectionException {
  const UsersAlreadyConnectedException([
    super.message = 'You are already connected to this user',
  ]);
}
