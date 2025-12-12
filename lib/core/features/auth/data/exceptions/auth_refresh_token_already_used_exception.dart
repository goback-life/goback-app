import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when attempting to use a refresh token that was already consumed.
///
/// **When it occurs:**
/// - Token rotation security: each refresh token can only be used once
/// - Concurrent session refresh attempts
///
/// **Common scenarios:**
/// - Multiple app instances refreshing simultaneously
/// - Replay attack prevention mechanism
class AuthRefreshTokenAlreadyUsedException extends AuthException {
  const AuthRefreshTokenAlreadyUsedException([String? code])
    : super('Refresh token already used', code: code);
}
