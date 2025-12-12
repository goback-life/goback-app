import 'package:cloudless/core/exceptions/main_exception.dart';

class TooManyRequestsException extends MainException {
  const TooManyRequestsException([
    super.message = 'Too many requests. Please try again later',
  ]) : super(code: null);
}
