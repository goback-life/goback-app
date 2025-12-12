import 'package:cloudless/core/exceptions/main_exception.dart';

class ConnectionException extends MainException {
  const ConnectionException(super.message, {super.code});
}
