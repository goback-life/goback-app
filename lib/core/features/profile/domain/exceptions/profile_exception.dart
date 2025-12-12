import 'package:cloudless/core/exceptions/main_exception.dart';

/// Base exception for profile-related errors.
abstract class ProfileException extends MainException {
  const ProfileException(super.message, {super.code});
}
