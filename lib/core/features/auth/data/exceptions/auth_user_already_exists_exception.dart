import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Phone is already registered and confirmed (full signup completed).
class AuthUserAlreadyExistsException extends AuthException {
  const AuthUserAlreadyExistsException([String? code])
    : super('User already exists', code: code);
}
