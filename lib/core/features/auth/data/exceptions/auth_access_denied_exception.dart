import 'package:cloudless/core/features/auth/domain/exceptions/auth_exception.dart';

/// Thrown when the authenticated user lacks permission to access a resource.
///
/// **When it occurs:**
/// - User has valid authentication but insufficient permissions
/// - Role-based access control denies the operation
/// - Resource-specific permissions are missing
///
/// **Common scenarios:**
/// - Admin-only operations attempted by regular users
/// - Access to other users' private data
/// - Operations requiring specific roles or permissions
class AuthAccessDeniedException extends AuthException {
  const AuthAccessDeniedException([String? code])
    : super('Access denied', code: code);
}
