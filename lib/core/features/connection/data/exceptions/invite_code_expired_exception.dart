import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class InviteCodeExpiredException extends ConnectionException {
  const InviteCodeExpiredException([
    super.message = 'Invite code has expired',
    String? code,
  ]) : super(code: code);
}
