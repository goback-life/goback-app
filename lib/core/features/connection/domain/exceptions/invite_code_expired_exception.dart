import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class InviteCodeExpiredException extends ConnectionException {
  const InviteCodeExpiredException([
    super.message = 'This invite code has expired',
  ]);
}
