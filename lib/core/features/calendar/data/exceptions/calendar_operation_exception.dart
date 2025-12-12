import 'package:cloudless/core/exceptions/main_exception.dart';

class CalendarOperationException extends MainException {
  const CalendarOperationException([String? message, String? code])
    : super(message ?? 'Calendar operation failed', code: code);
}
