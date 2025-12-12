import 'package:cloudless/core/features/connection/data/exceptions/connection_data_exception.dart';

class InviteCodeGenerationException extends ConnectionDataException {
  const InviteCodeGenerationException([
    super.message =
        'Failed to generate unique invite code after multiple attempts',
  ]);
}
