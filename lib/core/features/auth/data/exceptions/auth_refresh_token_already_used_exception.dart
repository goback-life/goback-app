import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Refresh token was already consumed (token rotation security).
class AuthRefreshTokenAlreadyUsedException extends AuthException {
  const AuthRefreshTokenAlreadyUsedException([String? code])
    : super('Refresh token already used', code: code);
}
