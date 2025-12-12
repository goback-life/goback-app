import 'package:cloudless/core/features/connection/data/exceptions/connection_data_exception.dart';

class InviteLimitException extends ConnectionDataException {
  const InviteLimitException([super.message = 'Invite limit reached']);
}
