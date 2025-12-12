import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class InviteCodeInvalidException extends ConnectionException {
  const InviteCodeInvalidException([
    super.message = 'Invalid invite code provided',
    String? code,
  ]) : super(code: code);
}
