import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Target user does not exist (unregistered phone or deleted account).
class AuthUserNotFoundException extends AuthException {
  const AuthUserNotFoundException([String? code])
    : super('User not found', code: code);
}
