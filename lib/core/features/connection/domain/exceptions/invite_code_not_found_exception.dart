import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class InviteCodeNotFoundException extends ConnectionException {
  const InviteCodeNotFoundException([
    super.message = 'Invite code not found or invalid',
  ]);
}
