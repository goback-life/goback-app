import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Phone exists but OTP verification was never completed.
class AuthPhoneNotConfirmedException extends AuthException {
  const AuthPhoneNotConfirmedException([String? code])
    : super('Phone number not confirmed', code: code);
}
