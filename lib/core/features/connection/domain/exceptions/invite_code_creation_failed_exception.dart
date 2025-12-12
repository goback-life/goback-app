import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class InviteCodeCreationFailedException extends ConnectionException {
  const InviteCodeCreationFailedException([
    super.message = 'Failed to create invite code. Please try again.',
  ]);
}
