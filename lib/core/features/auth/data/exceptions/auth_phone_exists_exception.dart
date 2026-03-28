import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Phone number is already registered (may not yet be confirmed).
class AuthPhoneExistsException extends AuthException {
  const AuthPhoneExistsException([String? code])
    : super('Phone number already exists', code: code);
}
