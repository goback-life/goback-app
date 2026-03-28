import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// User has valid auth but insufficient permissions for the resource.
class AuthAccessDeniedException extends AuthException {
  const AuthAccessDeniedException([String? code])
    : super('Access denied', code: code);
}
