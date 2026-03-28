import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// No active session exists (never logged in, cleared, or corrupted).
class AuthSessionNotFoundException extends AuthException {
  const AuthSessionNotFoundException([String? code])
    : super('Session not found', code: code);
}
