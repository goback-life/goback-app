import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when user account is banned or suspended.
///
/// **When it occurs:**
/// - Account violates terms of service
/// - Administrative suspension
/// - Security-related account blocking
///
/// **Common scenarios:**
/// - Policy violation detection
/// - Manual admin action
/// - Automated security triggers
class AuthUserBannedException extends AuthException {
  const AuthUserBannedException([String? code])
    : super('User account is banned', code: code);
}
