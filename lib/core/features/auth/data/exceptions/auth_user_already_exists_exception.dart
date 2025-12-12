import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when attempting to create a user that already exists.
///
/// **When it occurs:**
/// - Phone number already registered AND confirmed
/// - Complete signup flow already completed for this phone
///
/// **Common scenarios:**
/// - `signUp()` with fully registered and verified phone
/// - Differs from `phone_exists` (unconfirmed vs confirmed)
class AuthUserAlreadyExistsException extends AuthException {
  const AuthUserAlreadyExistsException([String? code])
    : super('User already exists', code: code);
}
