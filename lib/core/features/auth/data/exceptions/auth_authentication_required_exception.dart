import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when an operation requires authentication but no valid session exists.
///
/// **When it occurs:**
/// - Access to protected resources without authentication
/// - JWT token is missing or invalid
/// - Anonymous access to authenticated endpoints
///
/// **Common scenarios:**
/// - Database queries requiring authentication
/// - API calls to protected endpoints
/// - Operations on user-specific data without login
class AuthAuthenticationRequiredException extends AuthException {
  const AuthAuthenticationRequiredException([String? code])
    : super('Authentication required', code: code);
}
