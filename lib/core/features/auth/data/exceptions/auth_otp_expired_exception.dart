import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// OTP has expired (user entered code after expiration time).
class AuthOtpExpiredException extends AuthException {
  const AuthOtpExpiredException([String? code])
    : super('One-time password (OTP) expired', code: code);
}
