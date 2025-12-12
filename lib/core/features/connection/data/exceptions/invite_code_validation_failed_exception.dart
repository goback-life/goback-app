import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class InviteCodeValidationFailedException extends ConnectionException {
  const InviteCodeValidationFailedException([
    super.message = 'Invite code validation failed',
    String? code,
  ]) : super(code: code);
}
