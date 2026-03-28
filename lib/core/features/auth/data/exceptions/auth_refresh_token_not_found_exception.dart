import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Refresh token is not found, revoked, or invalid.
class AuthRefreshTokenNotFoundException extends AuthException {
  const AuthRefreshTokenNotFoundException([String? code])
    : super('Refresh token not found', code: code);
}
