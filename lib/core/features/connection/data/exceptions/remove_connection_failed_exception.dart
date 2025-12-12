import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class RemoveConnectionFailedException extends ConnectionException {
  const RemoveConnectionFailedException([
    super.message = 'Failed to remove connection',
    String? code,
  ]) : super(code: code);
}
