import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when no active session exists for the current user.
///
/// **When it occurs:**
/// - User was never logged in
/// - Session was manually cleared/deleted
///
/// **Common scenarios:**
/// - API calls without prior authentication
/// - Session corruption or manual logout
/// - Fresh app install without saved session
class AuthSessionNotFoundException extends AuthException {
  const AuthSessionNotFoundException([String? code])
    : super('Session not found', code: code);
}
