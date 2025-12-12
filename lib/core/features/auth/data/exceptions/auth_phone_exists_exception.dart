import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when attempting to register with an already existing phone number.
///
/// **When it occurs:**
/// - Phone number is already registered but may not be confirmed
/// - Duplicate signup attempts with same phone
///
/// **Common scenarios:**
/// - `signUp(phone: '+123', password: 'pwd')` with existing phone
/// - User forgot they already registered
class AuthPhoneExistsException extends AuthException {
  const AuthPhoneExistsException([String? code])
    : super('Phone number already exists', code: code);
}
