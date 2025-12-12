import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when trying to sign in with an unconfirmed phone number.
///
/// **When it occurs:**
/// - Phone exists in system but OTP verification was never completed
/// - Login attempt before phone confirmation
///
/// **Common scenarios:**
/// - `signInWithPassword()` with unverified phone
/// - User skipped OTP verification step during signup
class AuthPhoneNotConfirmedException extends AuthException {
  const AuthPhoneNotConfirmedException([String? code])
    : super('Phone number not confirmed', code: code);
}
