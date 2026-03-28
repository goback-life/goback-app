import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// OTP verification code is invalid, incorrect, or tampered with.
class AuthInvalidVerificationCodeException extends AuthException {
  const AuthInvalidVerificationCodeException([String? code])
    : super('Invalid verification code', code: code);
}
