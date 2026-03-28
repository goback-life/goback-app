import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// User account is banned or suspended by admin or automated triggers.
class AuthUserBannedException extends AuthException {
  const AuthUserBannedException([String? code])
    : super('User account is banned', code: code);
}
