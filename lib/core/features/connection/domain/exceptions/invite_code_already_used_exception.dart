import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class InviteCodeAlreadyUsedException extends ConnectionException {
  const InviteCodeAlreadyUsedException([
    super.message = 'This invite code has already been used',
  ]);
}
