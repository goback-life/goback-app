import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when the user session has expired due to inactivity.
///
/// **When it occurs:**
/// - JWT access token exceeded its lifetime
/// - Inactivity timeout reached
///
/// **Common scenarios:**
/// - Database queries with expired session
/// - App resumed after long background time
/// - Configurable session timeout reached
class AuthSessionExpiredException extends AuthException {
  const AuthSessionExpiredException([String? code])
    : super('Session expired', code: code);
}
