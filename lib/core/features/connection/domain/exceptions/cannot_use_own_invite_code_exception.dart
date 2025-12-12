import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class CannotUseOwnInviteCodeException extends ConnectionException {
  const CannotUseOwnInviteCodeException([
    super.message = 'You cannot use your own invite code',
  ]);
}
