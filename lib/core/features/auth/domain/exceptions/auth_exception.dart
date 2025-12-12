import 'package:cloudless/core/exceptions/main_exception.dart';

/// Base exception for authentication errors
abstract class AuthException extends MainException {
  const AuthException(super.message, {super.code});
}
