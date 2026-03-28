import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// JWT access token has expired due to inactivity or timeout.
class AuthSessionExpiredException extends AuthException {
  const AuthSessionExpiredException([String? code])
    : super('Session expired', code: code);
}
