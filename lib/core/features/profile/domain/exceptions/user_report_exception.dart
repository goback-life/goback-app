import 'package:cloudless/core/exceptions/main_exception.dart';

class UserReportException extends MainException {
  const UserReportException([String? message, String? code])
    : super(message ?? 'User report operation failed', code: code);
}
