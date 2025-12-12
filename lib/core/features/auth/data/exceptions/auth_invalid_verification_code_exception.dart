import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when verification code is invalid or incorrect.
///
/// **When it occurs:**
/// - User enters wrong OTP code
/// - Verification code format is invalid
/// - Code has been tampered with
///
/// **Common scenarios:**
/// - Typo in OTP input
/// - Using old/previous verification code
/// - Manual code manipulation
class AuthInvalidVerificationCodeException extends AuthException {
  const AuthInvalidVerificationCodeException([String? code])
    : super('Invalid verification code', code: code);
}
