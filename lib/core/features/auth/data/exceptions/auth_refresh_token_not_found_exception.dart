import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when the refresh token is not found or invalid.
///
/// **When it occurs:**
/// - Token was revoked or expired
/// - Invalid token provided to refresh session
///
/// **Common scenarios:**
/// - `refreshSession()` with corrupted token
/// - User logged out from another device
/// - Token cleanup after security breach
class AuthRefreshTokenNotFoundException extends AuthException {
  const AuthRefreshTokenNotFoundException([String? code])
    : super('Refresh token not found', code: code);
}
