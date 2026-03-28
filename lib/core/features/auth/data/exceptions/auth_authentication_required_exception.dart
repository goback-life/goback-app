import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Operation requires authentication but no valid session exists.
class AuthAuthenticationRequiredException extends AuthException {
  const AuthAuthenticationRequiredException([String? code])
    : super('Authentication required', code: code);
}
