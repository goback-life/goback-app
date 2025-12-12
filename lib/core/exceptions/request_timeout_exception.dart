import 'package:cloudless/core/exceptions/main_exception.dart';

class RequestTimeoutException extends MainException {
  const RequestTimeoutException([super.message = 'Request timed out.'])
    : super(code: null);
}
