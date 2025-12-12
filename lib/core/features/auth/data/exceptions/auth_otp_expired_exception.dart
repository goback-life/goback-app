import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when a one-time password (OTP) has expired.
///
/// **When it occurs:**
/// - User enters OTP after the expiration time (default: 60 seconds)
/// - Delayed OTP verification during signup or login
///
/// **Common scenarios:**
/// - `verifyOtp()` called with expired token
/// - Network delays causing OTP timeout
class AuthOtpExpiredException extends AuthException {
  const AuthOtpExpiredException([String? code])
    : super('One-time password (OTP) expired', code: code);
}
