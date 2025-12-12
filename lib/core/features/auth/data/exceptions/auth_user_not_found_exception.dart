import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when operations target a non-existent user.
///
/// **When it occurs:**
/// - Login attempt with never-registered phone
/// - Operations on deleted user accounts
///
/// **Common scenarios:**
/// - `signInWithPassword()` with unregistered phone
/// - `updateUser()` with corrupted session
/// - Password reset for non-existent phone
class AuthUserNotFoundException extends AuthException {
  const AuthUserNotFoundException([String? code])
    : super('User not found', code: code);
}
